from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.CreateModel(
            name='Site',
            fields=[
                ('id',                   models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name',                 models.CharField(max_length=100)),
                ('domain',               models.CharField(blank=True, max_length=253)),
                ('site_type',            models.CharField(
                    choices=[('web', 'Web / Frontend'), ('api', 'API / Backend'), ('fullstack', 'Fullstack (Web + API)')],
                    default='web',
                    max_length=20,
                )),
                ('status',               models.CharField(
                    choices=[('idle', 'Idle'), ('deploying', 'Deploying'), ('running', 'Running'), ('stopped', 'Stopped'), ('error', 'Error')],
                    default='idle',
                    max_length=20,
                )),
                ('github_repo',          models.CharField(blank=True, help_text='owner/repo', max_length=500)),
                ('github_branch',        models.CharField(default='main', max_length=100)),
                ('github_token',         models.CharField(blank=True, help_text='Personal Access Token', max_length=500)),
                ('web_container_name',   models.CharField(blank=True, max_length=100)),
                ('api_container_name',   models.CharField(blank=True, max_length=100)),
                ('web_port',             models.IntegerField(blank=True, null=True)),
                ('api_port',             models.IntegerField(blank=True, null=True)),
                ('ssl_enabled',          models.BooleanField(default=False)),
                ('ssl_email',            models.EmailField(blank=True, max_length=254)),
                ('created_at',           models.DateTimeField(auto_now_add=True)),
                ('updated_at',           models.DateTimeField(auto_now=True)),
                ('user',                 models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='sites',
                    to='auth.user',
                )),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
