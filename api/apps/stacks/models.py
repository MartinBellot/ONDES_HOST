import uuid

from django.db import models
from django.contrib.auth.models import User


class ComposeApp(models.Model):
    """
    Represents a project deployed via docker-compose from a GitHub repo.
    This replaces the old Site model as the primary deployment unit.
    """
    STATUS_CHOICES = [
        ('idle',      'Idle'),
        ('cloning',   'Clonage du dépôt...'),
        ('building',  'Build en cours...'),
        ('starting',  'Démarrage...'),
        ('running',   'En cours'),
        ('stopped',   'Arrêté'),
        ('error',     'Erreur'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='compose_apps')

    # ── Identification ────────────────────────────────────────────────────────
    name = models.CharField(max_length=100, help_text='Nom affiché dans le dashboard')

    # ── Source GitHub ─────────────────────────────────────────────────────────
    github_repo   = models.CharField(max_length=500, help_text='owner/repo')
    github_branch = models.CharField(max_length=100, default='main')
    compose_file  = models.CharField(max_length=500, default='docker-compose.yml',
                                     help_text='Chemin relatif vers le fichier compose dans le repo')

    # ── Configuration ─────────────────────────────────────────────────────────
    env_vars = models.JSONField(
        default=dict,
        help_text='Variables d\'environnement injectées dans le .env avant docker compose up',
    )

    # ── État ──────────────────────────────────────────────────────────────────
    status         = models.CharField(max_length=20, choices=STATUS_CHOICES, default='idle')
    status_message = models.TextField(blank=True, help_text='Dernier message de log ou d\'erreur')
    project_dir    = models.CharField(max_length=500, blank=True,
                                      help_text='Répertoire où le repo est cloné sur le serveur')

    # ── Optionnel ─────────────────────────────────────────────────────────────
    domain          = models.CharField(max_length=253, blank=True,
                                       help_text='Domaine associé à ce projet')
    current_commit_sha = models.CharField(
        max_length=40, blank=True,
        help_text='SHA du commit actuellement déployé (capturé après chaque déploiement)',
    )
    last_deployed_at = models.DateTimeField(null=True, blank=True)

    # ── Webhook CI/CD ─────────────────────────────────────────────────────────
    webhook_token = models.UUIDField(
        default=uuid.uuid4,
        unique=True,
        editable=False,
        help_text='Token secret pour déclencher un redéploiement depuis GitHub Actions',
    )

    created_at      = models.DateTimeField(auto_now_add=True)
    updated_at      = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.github_repo}@{self.github_branch})'
