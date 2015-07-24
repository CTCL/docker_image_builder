FROM fedora
RUN dnf install -y git
RUN dnf install -y python-pip
RUN dnf install -y tar
RUN pip install awscli
COPY ./build.sh .
RUN chmod 755 build.sh
CMD source ./build.sh
