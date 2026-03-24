import os
import platform

import docker
from docker.errors import NotFound, APIError, DockerException


def get_client():
    """
    Connect to the Docker daemon.
    On macOS with Docker Desktop, the socket may not be at the standard
    /var/run/docker.sock path — we try alternate locations automatically.
    """
    try:
        return docker.from_env()
    except DockerException:
        if platform.system() == 'Darwin':
            home = os.path.expanduser('~')
            alt_socks = [
                f'unix://{home}/.docker/run/docker.sock',
                f'unix://{home}/Library/Containers/com.docker.docker/Data/docker.sock',
            ]
            for sock in alt_socks:
                try:
                    client = docker.DockerClient(base_url=sock)
                    client.ping()
                    return client
                except Exception:
                    continue
        raise


def list_containers(all_containers: bool = True) -> list:
    client = get_client()
    containers = client.containers.list(all=all_containers)
    return [
        {
            'id': c.short_id,
            'name': c.name,
            'image': c.image.tags[0] if c.image.tags else c.image.short_id,
            'status': c.status,
            'ports': c.ports,
        }
        for c in containers
    ]


def start_container(container_id: str) -> dict:
    client = get_client()
    container = client.containers.get(container_id)
    container.start()
    return {'status': 'started', 'id': container.short_id}


def stop_container(container_id: str) -> dict:
    client = get_client()
    container = client.containers.get(container_id)
    container.stop()
    return {'status': 'stopped', 'id': container.short_id}


def create_container(
    name: str,
    image: str,
    host_port: int,
    container_port: int,
    volume_host: str = '',
    volume_container: str = '',
) -> dict:
    client = get_client()
    volumes = {}
    if volume_host and volume_container:
        volumes[volume_host] = {'bind': volume_container, 'mode': 'rw'}

    container = client.containers.run(
        image=image,
        name=name,
        ports={f'{container_port}/tcp': host_port},
        volumes=volumes or None,
        detach=True,
    )
    return {
        'id': container.short_id,
        'name': container.name,
        'status': container.status,
    }


def remove_container(container_id: str, force: bool = True) -> dict:
    client = get_client()
    container = client.containers.get(container_id)
    container.remove(force=force)
    return {'status': 'removed', 'id': container_id}
