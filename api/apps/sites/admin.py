from django.contrib import admin
from .models import Site


@admin.register(Site)
class SiteAdmin(admin.ModelAdmin):
    list_display  = ('name', 'domain', 'site_type', 'status', 'ssl_enabled', 'user', 'created_at')
    list_filter   = ('site_type', 'status', 'ssl_enabled')
    search_fields = ('name', 'domain', 'user__username')
    readonly_fields = ('created_at', 'updated_at', 'web_container_name', 'api_container_name', 'web_port', 'api_port')
    ordering = ('-created_at',)
