FROM alpine:latest

RUN apk add --no-cache iptables openvpn dumb-init bind-tools

RUN echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf \
    && echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf \
    && echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf \
    && echo 'net.ipv6.conf.eth0.disable_ipv6 = 1' >> /etc/sysctl.conf

ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ADD health-check.sh /usr/local/bin/health-check.sh

ENTRYPOINT ["dumb-init", "/usr/local/bin/entrypoint.sh", "--"]

HEALTHCHECK --interval=5m CMD /usr/local/bin/health-check.sh
