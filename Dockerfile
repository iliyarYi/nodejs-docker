FROM centos/s2i-base-centos7
MAINTAINER "Yiliyaer"

EXPOSE 8080
ENV NODEJS_VERSION=8 \
    NPM_RUN=start \
    NAME=nodejs \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH

ENV SUMMARY="Platform for building and running Node.js $NODEJS_VERSION applications" \
    DESCRIPTION="my nodejs image"

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Node.js $NODEJS_VERSION" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,$NAME,$NAME$NODEJS_VERSION" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      com.redhat.dev-mode="DEV_MODE:false" \
      com.redhat.deployments-dir="${APP_ROOT}/src" \
      com.redhat.dev-mode.port="DEBUG_PORT:5858"\
      com.redhat.component="rh-$NAME$NODEJS_VERSION-docker" \
      name="centos/$NAME-$NODEJS_VERSION-centos7" \
      version="$NODEJS_VERSION" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>" \
      help="For more information visit https://github.com/sclorg/s2i-nodejs-container" \
      usage="s2i build <SOURCE-REPOSITORY> centos/$NAME-$NODEJS_VERSION-centos7:latest <APP-NAME>"

RUN yum install -y centos-release-scl-rh && \
    yum remove -y rh-nodejs6\* && \
    yum-config-manager --enable centos-sclo-rh-testing && \
    INSTALL_PKGS="rh-nodejs8 rh-nodejs8-npm rh-nodejs8-nodejs-nodemon nss_wrapper" && \
    ln -s /usr/lib/node_modules/nodemon/bin/nodemon.js /usr/bin/nodemon && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y

#install crontab
RUN yum -y install cronie
#install EPEL
RUN yum install epel-release -y
#install nginx
RUN yum install nginx -y
#install apache
RUN yum install httpd -y
#install socat
RUN yum install socat -y
#install npm/nodejs
RUN curl -sL https://rpm.nodesource.com/setup_8.x | bash -
RUN yum install -y nodejs; yum clean all -y

RUN echo "Packages are all installed. Now installing acme script."
RUN curl https://get.acme.sh | sh

RUN mkdir /opt/app-root/src/.ssh && chmod 700 /opt/app-root/src/.ssh

COPY ./tmp/config /opt/app-root/src/.ssh
RUN chmod 400 /opt/app-root/src/.ssh

RUN chmod g+w /etc/passwd

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image, including help file.
COPY ./root/ /

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:0 ${APP_ROOT} && chmod -R ug+rwx ${APP_ROOT} && \
    rpm-file-permissions

USER 1001

RUN npm install

CMD [ "npm", " ." ]