from django.db import models


class NginxVhost(models.Model):
    """
    Represents an NGINX reverse-proxy vhost for a deployed ComposeApp stack.
    One stack can have multiple vhosts (e.g. frontend on port 3000 + API on port 8080).
    """
    SSL_STATUS_CHOICES = [
        ('none',    'Pas de SSL'),
        ('pending', 'Obtention en cours'),
        ('active',  'SSL actif'),
        ('error',   "Erreur d'obtention"),
        ('expired', 'Certificat expiré'),
    ]

    stack = models.ForeignKey(
        'stacks.ComposeApp',
        on_delete=models.CASCADE,
        related_name='vhosts',
    )
    # Human-readable label for the service this vhost fronts (e.g. "frontend", "api")
    service_label  = models.CharField(max_length=50, default='app')
    domain         = models.CharField(max_length=253, unique=True)
    upstream_port  = models.IntegerField(
        help_text='Port exposé sur l\'hôte par le container applicatif',
    )
    container_name = models.CharField(
        max_length=255, blank=True,
        help_text='Nom du container Docker sélectionné lors de la création (référence)',
    )

    # ── SSL ───────────────────────────────────────────────────────────────────
    ssl_enabled   = models.BooleanField(default=False)
    ssl_email     = models.EmailField(blank=True)
    ssl_status    = models.CharField(
        max_length=20, choices=SSL_STATUS_CHOICES, default='none',
    )
    ssl_expires_at  = models.DateTimeField(null=True, blank=True)
    certbot_output  = models.TextField(blank=True)

    # ── Multi-service routing ─────────────────────────────────────────────────
    # When a repo nginx config routes different paths to different services
    # (e.g. /api/ → Django, / → Next.js) this stores the full routing map:
    #   [{"path": "/api/", "upstream_port": 8001},
    #    {"path": "/",     "upstream_port": 3001}]
    # Routes are sorted most-specific-first at write time.
    # When empty, falls back to the single upstream_port for location /.
    route_overrides = models.JSONField(default=list, blank=True)

    # ── www redirect ─────────────────────────────────────────────────────────
    # When True, a separate server block for www.{domain} is generated that
    # redirects all traffic to the canonical {domain}.  For SSL, certbot is
    # also requested with "-d www.{domain}" so the cert covers both names.
    include_www = models.BooleanField(
        default=False,
        help_text='Génère un bloc nginx www.domain qui redirige vers domain (+ cert www).',
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['domain']

    def __str__(self):
        ssl_flag = ' [SSL]' if self.ssl_enabled else ''
        return f'{self.domain} → :{self.upstream_port}{ssl_flag} (stack {self.stack_id})'
