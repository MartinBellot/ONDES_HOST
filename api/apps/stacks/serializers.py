from rest_framework import serializers
from .models import ComposeApp


class ComposeAppSerializer(serializers.ModelSerializer):
    class Meta:
        model = ComposeApp
        fields = '__all__'
        read_only_fields = ('user', 'status', 'status_message', 'project_dir',
                            'last_deployed_at', 'created_at', 'updated_at')


class ComposeAppCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ComposeApp
        fields = ('name', 'github_repo', 'github_branch', 'compose_file', 'env_vars', 'domain')

    def validate_github_repo(self, value):
        if '/' not in value:
            raise serializers.ValidationError('Doit être au format owner/repo')
        return value.strip('/')
