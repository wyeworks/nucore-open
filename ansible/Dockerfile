FROM fedora

RUN yum install procps openssh-server -y
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

COPY docker-entrypoint.sh /entrypoint.sh
COPY id_rsa.pub /root/id_rsa.pub
RUN mkdir -p /root/.ssh && cat /root/id_rsa.pub > /root/.ssh/authorized_keys

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
