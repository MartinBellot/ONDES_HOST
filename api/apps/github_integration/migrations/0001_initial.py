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
            name='GitHubProfile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('login', models.CharField(max_length=100)),
                ('name', models.CharField(blank=True, max_length=200)),
                ('avatar_url', models.URLField(blank=True)),
                ('access_token', models.CharField(max_length=500)),
                ('token_scope', models.CharField(blank=True, max_length=500)),
                ('connected_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='github_profile',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
        ),
    ]
