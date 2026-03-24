from django.db import models
from django.contrib.auth.models import User


class GitHubProfile(models.Model):
    """
    Stores the OAuth access token for a user's connected GitHub account.
    One profile per user — connecting again replaces the existing entry.
    """
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='github_profile'
    )
    login = models.CharField(max_length=100)
    name = models.CharField(max_length=200, blank=True)
    avatar_url = models.URLField(blank=True)
    access_token = models.CharField(max_length=500)
    token_scope = models.CharField(max_length=500, blank=True)
    connected_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'{self.user.username} → @{self.login}'


class GitHubOAuthConfig(models.Model):
    """
    Singleton row: stores the GitHub OAuth App credentials entered via the UI.
    Instead of relying on .env variables, admins configure these directly
    in the application interface.
    """
    client_id = models.CharField(max_length=200)
    client_secret = models.CharField(max_length=200)
    configured_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'GitHub OAuth Config'

    def __str__(self):
        return f'GitHub OAuth Config (client_id={self.client_id[:8]}…)'

    @classmethod
    def get(cls):
        """Return the singleton instance, or None if not yet configured."""
        return cls.objects.first()
