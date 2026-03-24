from django.urls import path
from .views import ContainerListView, ContainerActionView, CreateContainerView, DockerStatusView

urlpatterns = [
    path('status/', DockerStatusView.as_view(), name='docker-status'),
    path('containers/', ContainerListView.as_view(), name='container-list'),
    path('containers/create/', CreateContainerView.as_view(), name='container-create'),
    path('containers/<str:container_id>/<str:action>/', ContainerActionView.as_view(), name='container-action'),
]
