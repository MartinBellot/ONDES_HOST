from django.urls import path
from .views import (
    GitHubOAuthConfigView,
    GitHubOAuthStartView,
    GitHubOAuthCallbackView,
    GitHubProfileView,
    GitHubReposView,
    GitHubBranchesView,
    GitHubComposeFilesView,
)

urlpatterns = [
    # OAuth App config (managed from app UI)
    path('config/',         GitHubOAuthConfigView.as_view(),   name='github-oauth-config'),
    # OAuth
    path('oauth/start/',    GitHubOAuthStartView.as_view(),    name='github-oauth-start'),
    path('oauth/callback/', GitHubOAuthCallbackView.as_view(), name='github-oauth-callback'),
    # Profile
    path('profile/',        GitHubProfileView.as_view(),       name='github-profile'),
    # Browser
    path('repos/',                                         GitHubReposView.as_view(),        name='github-repos'),
    path('repos/<str:owner>/<str:repo>/branches/',         GitHubBranchesView.as_view(),     name='github-branches'),
    path('repos/<str:owner>/<str:repo>/compose-files/',    GitHubComposeFilesView.as_view(), name='github-compose-files'),
]
