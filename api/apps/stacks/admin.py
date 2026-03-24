from django.contrib import admin
from .models import ComposeApp


@admin.register(ComposeApp)
class ComposeAppAdmin(admin.ModelAdmin):
    list_display = ('name', 'user', 'github_repo', 'github_branch', 'status', 'last_deployed_at')
    list_filter = ('status',)
    readonly_fields = ('status', 'status_message', 'project_dir', 'last_deployed_at', 'created_at', 'updated_at')
