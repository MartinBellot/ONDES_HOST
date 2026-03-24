from django.urls import re_path
from .consumers import DeployConsumer

websocket_urlpatterns = [
    re_path(r'ws/deploy/(?P<stack_id>\d+)/$', DeployConsumer.as_asgi()),
]
