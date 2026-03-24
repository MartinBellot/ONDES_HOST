"""
GitHub REST API v3 wrapper — uses OAuth access tokens.
No third-party library needed, just urllib.
"""
import base64
import json
import urllib.request
import urllib.error
import urllib.parse
from typing import Any

_GITHUB_API = 'https://api.github.com'


def _get(path: str, token: str) -> Any:
    url = f'{_GITHUB_API}{path}'
    req = urllib.request.Request(
        url,
        headers={
            'Authorization': f'Bearer {token}',
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'Ondes-Dashboard/1.0',
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def exchange_code_for_token(client_id: str, client_secret: str, code: str) -> dict:
    """Exchange an OAuth authorization code for an access token."""
    data = urllib.parse.urlencode({
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
    }).encode()
    req = urllib.request.Request(
        'https://github.com/login/oauth/access_token',
        data=data,
        headers={'Accept': 'application/json', 'User-Agent': 'Ondes-Dashboard/1.0'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def get_authenticated_user(token: str) -> dict:
    return _get('/user', token)


def list_repos(token: str, page: int = 1, per_page: int = 50) -> list:
    return _get(f'/user/repos?sort=updated&per_page={per_page}&page={page}', token)


def list_branches(token: str, owner: str, repo: str) -> list:
    return _get(f'/repos/{owner}/{repo}/branches', token)


def get_repo(token: str, owner: str, repo: str) -> dict:
    return _get(f'/repos/{owner}/{repo}', token)


def list_repo_contents(token: str, owner: str, repo: str, path: str = '', branch: str = 'main') -> list:
    """List files/directories at the given path in a repo."""
    encoded_path = urllib.parse.quote(path, safe='/')
    url = f'/repos/{owner}/{repo}/contents/{encoded_path}?ref={urllib.parse.quote(branch)}'
    result = _get(url, token)
    if isinstance(result, list):
        return result
    # Single file — wrap in list
    return [result]


def get_file_content(token: str, owner: str, repo: str, path: str, branch: str = 'main') -> str:
    """Return the decoded text content of a file in a repo."""
    encoded_path = urllib.parse.quote(path, safe='/')
    data = _get(
        f'/repos/{owner}/{repo}/contents/{encoded_path}?ref={urllib.parse.quote(branch)}',
        token,
    )
    if data.get('encoding') == 'base64':
        return base64.b64decode(data['content'].replace('\n', '')).decode('utf-8', errors='replace')
    return data.get('content', '')


def find_compose_files(token: str, owner: str, repo: str, branch: str = 'main') -> list[str]:
    """
    Scan the root of the repo for docker-compose files.
    Returns a list of filenames like ['docker-compose.yml', 'docker-compose.prod.yml'].
    """
    try:
        files = list_repo_contents(token, owner, repo, '', branch)
        return [
            f['name'] for f in files
            if isinstance(f, dict)
            and f.get('type') == 'file'
            and ('docker-compose' in f['name'].lower() or f['name'].lower() in ('compose.yml', 'compose.yaml'))
            and f['name'].endswith(('.yml', '.yaml'))
        ]
    except Exception:
        return []


def detect_env_template(token: str, owner: str, repo: str, branch: str = 'main') -> dict[str, str]:
    """
    Try to read .env.example or .env.sample and return a dict of
    {KEY: default_value_or_empty_string}.
    """
    for candidate in ['.env.example', '.env.sample', '.env.template']:
        try:
            content = get_file_content(token, owner, repo, candidate, branch)
            return _parse_dotenv(content)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                continue
            raise
    return {}


def _parse_dotenv(content: str) -> dict[str, str]:
    """Parse a .env file into {KEY: value} — strips comments and blank lines."""
    result = {}
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, _, value = line.partition('=')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            result[key] = value
    return result
