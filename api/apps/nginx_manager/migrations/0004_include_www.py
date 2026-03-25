from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('nginx_manager', '0003_route_overrides'),
    ]

    operations = [
        migrations.AddField(
            model_name='nginxvhost',
            name='include_www',
            field=models.BooleanField(
                default=False,
                help_text='Génère un bloc nginx www.domain qui redirige vers domain (+ cert www).',
            ),
        ),
    ]
