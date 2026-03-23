from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.CreateModel(
            name='ContainerConfig',
            fields=[
                ('id',               models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name',             models.CharField(max_length=100, unique=True)),
                ('image',            models.CharField(max_length=200)),
                ('host_port',        models.IntegerField()),
                ('container_port',   models.IntegerField(default=80)),
                ('volume_host',      models.CharField(blank=True, max_length=500)),
                ('volume_container', models.CharField(blank=True, max_length=500)),
                ('created_at',       models.DateTimeField(auto_now_add=True)),
                ('user',             models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='containers',
                    to='auth.user',
                )),
            ],
        ),
    ]
