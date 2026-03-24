from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ComposeApp',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100)),
                ('github_repo', models.CharField(max_length=500)),
                ('github_branch', models.CharField(default='main', max_length=100)),
                ('compose_file', models.CharField(default='docker-compose.yml', max_length=500)),
                ('env_vars', models.JSONField(default=dict)),
                ('status', models.CharField(
                    choices=[
                        ('idle', 'Idle'), ('cloning', 'Clonage...'), ('building', 'Build...'),
                        ('starting', 'Démarrage...'), ('running', 'En cours'),
                        ('stopped', 'Arrêté'), ('error', 'Erreur'),
                    ],
                    default='idle', max_length=20,
                )),
                ('status_message', models.TextField(blank=True)),
                ('project_dir', models.CharField(blank=True, max_length=500)),
                ('domain', models.CharField(blank=True, max_length=253)),
                ('last_deployed_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='compose_apps',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
