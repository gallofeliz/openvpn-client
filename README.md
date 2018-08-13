# openvpn-client

Light, secure and easy-to-use openvpn client : a very light container based on Alpine, secured by iptables and startup checks and
provider-agnostic ... Put you ovpn file and enjoy !

Tested on x86_64 and ARM (raspberry).

## How to use

- First, get the ovpn file from your VPN provider (default name .ovpn) ;
- Then, create a file with your VPN login and password separated by a line break (default name .ovpn-pass).

Nothing more, just start the container as docker-compose.yml below ... too easy ? Sorry.

```
    version: '3.5'
    services:
      vpn:
        restart: unless-stopped
        build:
          context: .
          dockerfile: Dockerfile
        cap_add:
          - NET_ADMIN
        devices:
          - /dev/net/tun
        volumes:
          - ./.ovpn:/usr/local/etc/.ovpn:ro
          - ./.ovpn-pass:/usr/local/etc/.ovpn-pass:ro

    networks:
      default:
          name: vpn-network
```

Now, you want your application container to use this VPN. Here an example :

```
    version: '3.5'
    services:
      myApp:
        restart: unless-stopped
        image: myApp
        network_mode: container:vpn_vpn_1
```

Note that vpn_vpn_1 is the vpn container name. You need to adapt. This is 2 separates docker-compose because we can have differents applications that use
the same VPN ...

Now, we want to be able to call a HTTP endpoint inside our application. An example with Traefik :

```
    version: '3.5'
    services:
      myApp:
        restart: unless-stopped
        image: myApp
        network_mode: container:vpn_vpn_1
        labels:
          - "traefik.ng.frontend.rule=Host:myApp.local"
          - "traefik.ng.port=8080"
```

```
    version: '3.5'
    services:
      traefik:
        restart: unless-stopped
        image: traefik
        command:
          - "--api"
          - "--docker"
          - "--defaultentrypoints=https,http"
          - "--entryPoints=Name:https Address::443 TLS Compress:true"
          - "--entryPoints=Name:http Address::80 Compress:true"
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        ports:
          - 80:80
          - 443:443

    networks:
      default:
          name: vpn-network
```

Now you can make a HTTP request on your host on 80/443 on myApp.local. Cool, no ?

Enjoy :)

In case of problem : https://github.com/gallofeliz/openvpn-client

¡ El Gallo Feliz !