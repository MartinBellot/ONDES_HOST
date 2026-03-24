"""
Deploy pipeline for ComposeApp:
  1. Clone the GitHub repo using the user's stored OAuth token
  2. Write a .env file from app.env_vars
  3. Run `docker compose up -d --build`
  4. Stream logs in real-time via Django Channels groups

Each log line is broadcast to group `deploy_{app_id}` so the WebSocket
consumer can forward it to the connected client.
"""
import os
import shutil
import subprocess
import tempfile
import threading
from datetime import datetime, timezone

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from .models import ComposeApp


def _broadcast(app_id: int, message: str, level: str = 'info'):
    """Send a log line to the WebSocket group for this deploy."""
    try:
        layer = get_channel_layer()
        async_to_sync(layer.group_send)(
            f'deploy_{app_id}',
            {'type': 'deploy.log', 'message': message, 'level': level},
        )
    except Exception:
        pass  # Channel layer may not be available in some test contexts


def _set_status(app: ComposeApp, s: str, msg: str = ''):
    app.status = s
    app.status_message = msg
    app.save(update_fields=['status', 'status_message'])
    try:
        layer = get_channel_layer()
        async_to_sync(layer.group_send)(
            f'deploy_{app.id}',
            {'type': 'deploy.status', 'status': s, 'message': msg},
        )
    except Exception:
        pass


def _run_streaming(cmd: list, cwd: str, app_id: int, env: dict | None = None) -> int:
    """Run a subprocess and broadcast each output line to the WebSocket group."""
    proc = subprocess.Popen(
        cmd,
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    for line in proc.stdout:
        _broadcast(app_id, line.rstrip())
    proc.wait()
    return proc.returncode


def deploy_app(app_id: int):
    """
    Entry point called from the view in a background thread.
    Fetches a fresh copy of the app from DB (thread-safe).
    """
    app = ComposeApp.objects.select_related('user__github_profile').get(pk=app_id)

    try:
        token = app.user.github_profile.access_token
    except Exception:
        _set_status(app, 'error', 'Compte GitHub non connecté — connectez GitHub d\'abord.')
        _broadcast(app_id, '❌ Compte GitHub non connecté.', 'error')
        return

    project_dir = app.project_dir or tempfile.mkdtemp(prefix=f'ondes_{app.id}_')
    app.project_dir = project_dir
    app.save(update_fields=['project_dir'])

    _broadcast(app_id, f'🚀 Démarrage du déploiement de {app.name}...')

    # ── 1. Clone / pull ───────────────────────────────────────────────────────
    _set_status(app, 'cloning', 'Clonage du dépôt GitHub...')
    repo = app.github_repo.strip('/')
    branch = app.github_branch or 'main'
    clone_url = f'https://{token}@github.com/{repo}.git'

    if os.path.exists(os.path.join(project_dir, '.git')):
        _broadcast(app_id, f'📦 Mise à jour du dépôt (git pull origin {branch})...')
        rc = _run_streaming(
            ['git', 'pull', 'origin', branch],
            cwd=project_dir,
            app_id=app_id,
        )
    else:
        _broadcast(app_id, f'📦 Clonage de {repo}@{branch}...')
        # Clean dir before cloning
        if os.path.exists(project_dir):
            shutil.rmtree(project_dir)
        rc = _run_streaming(
            ['git', 'clone', '--depth', '1', '--branch', branch, clone_url, project_dir],
            cwd=tempfile.gettempdir(),
            app_id=app_id,
        )

    if rc != 0:
        _set_status(app, 'error', 'Échec du clonage — vérifiez le nom du dépôt et vos permissions GitHub.')
        _broadcast(app_id, '❌ Clonage échoué.', 'error')
        return

    _broadcast(app_id, '✅ Dépôt cloné avec succès.')

    # ── 2. Write .env ─────────────────────────────────────────────────────────
    if app.env_vars:
        env_path = os.path.join(project_dir, '.env')
        _broadcast(app_id, f'📝 Écriture du fichier .env ({len(app.env_vars)} variables)...')
        with open(env_path, 'w') as f:
            for k, v in app.env_vars.items():
                f.write(f'{k}={v}\n')

    # ── 3. docker compose up ──────────────────────────────────────────────────
    compose_path = os.path.join(project_dir, app.compose_file)
    if not os.path.exists(compose_path):
        _set_status(app, 'error', f'Fichier {app.compose_file} introuvable dans le dépôt.')
        _broadcast(app_id, f'❌ {app.compose_file} introuvable.', 'error')
        return

    _set_status(app, 'building', 'Build et démarrage des containers...')
    _broadcast(app_id, f'🐳 Lancement de docker compose -f {app.compose_file} up -d --build...')

    # Use a unique project name to avoid collisions between apps
    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'

    rc = _run_streaming(
        ['docker', 'compose', '-f', app.compose_file, '-p', project_name, 'up', '-d', '--build'],
        cwd=project_dir,
        app_id=app_id,
    )

    if rc != 0:
        _set_status(app, 'error', 'docker compose up a échoué — consultez les logs ci-dessus.')
        _broadcast(app_id, '❌ Déploiement échoué.', 'error')
        return

    app.status = 'running'
    app.status_message = ''
    app.last_deployed_at = datetime.now(tz=timezone.utc)
    app.save(update_fields=['status', 'status_message', 'last_deployed_at'])

    _broadcast(app_id, '🎉 Déploiement réussi ! Tous les containers sont démarrés.', 'success')
    _set_status(app, 'running')


def stop_app(app_id: int):
    app = ComposeApp.objects.get(pk=app_id)
    if not app.project_dir or not os.path.exists(app.project_dir):
        return {'error': 'Répertoire du projet introuvable.'}

    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'
    result = subprocess.run(
        ['docker', 'compose', '-f', app.compose_file, '-p', project_name, 'stop'],
        cwd=app.project_dir,
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        _set_status(app, 'stopped')
        return {'status': 'stopped'}
    return {'error': result.stderr}


def start_app(app_id: int):
    app = ComposeApp.objects.get(pk=app_id)
    if not app.project_dir or not os.path.exists(app.project_dir):
        # Re-deploy from scratch
        threading.Thread(target=deploy_app, args=(app_id,), daemon=True).start()
        return {'status': 'deploying'}

    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'
    result = subprocess.run(
        ['docker', 'compose', '-f', app.compose_file, '-p', project_name, 'start'],
        cwd=app.project_dir,
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        _set_status(app, 'running')
        return {'status': 'running'}
    return {'error': result.stderr}


def restart_app(app_id: int):
    app = ComposeApp.objects.get(pk=app_id)
    if not app.project_dir or not os.path.exists(app.project_dir):
        return {'error': 'Répertoire du projet introuvable.'}

    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'
    result = subprocess.run(
        ['docker', 'compose', '-f', app.compose_file, '-p', project_name, 'restart'],
        cwd=app.project_dir,
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        _set_status(app, 'running')
        return {'status': 'running'}
    return {'error': result.stderr}


def remove_app(app_id: int):
    """docker compose down + cleanup of the cloned directory."""
    app = ComposeApp.objects.get(pk=app_id)
    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'

    if app.project_dir and os.path.exists(app.project_dir):
        subprocess.run(
            ['docker', 'compose', '-f', app.compose_file, '-p', project_name, 'down', '--volumes'],
            cwd=app.project_dir,
            capture_output=True,
        )
        shutil.rmtree(app.project_dir, ignore_errors=True)

    app.delete()
    return {'status': 'removed'}


def get_logs(app_id: int, lines: int = 200) -> str:
    """Return recent logs from all containers in the compose project."""
    app = ComposeApp.objects.get(pk=app_id)
    if not app.project_dir or not os.path.exists(app.project_dir):
        return 'Aucun répertoire de projet trouvé.'

    project_name = f'ondes_{app.id}_{app.name.lower().replace(" ", "_")}'
    result = subprocess.run(
        ['docker', 'compose', '-f', app.compose_file, '-p', project_name,
         'logs', '--tail', str(lines), '--no-color'],
        cwd=app.project_dir,
        capture_output=True, text=True,
    )
    return result.stdout + result.stderr
