from django.contrib import admin
from .models import ContainerConfig


@admin.register(ContainerConfig)
class ContainerConfigAdmin(admin.ModelAdmin):
    list_display  = ('name', 'image', 'host_port', 'container_port', 'user', 'created_at')
    search_fields = ('name', 'image', 'user__username')
    readonly_fields = ('created_at',)
