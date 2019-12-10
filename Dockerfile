FROM centos:7 as exp-builder
WORKDIR /root
RUN curl -o /etc/yum.repos.d/vbatts-bazel-epel-7.repo https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install bazel git
RUN yum -y --setopt=tsflags=nodocs groupinstall 'Development Tools'
RUN curl -O https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.11.5.linux-amd64.tar.gz
RUN mkdir -p /root/gocode/bin /root/gocode/src
ENV GOPATH /root/gocode
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin
RUN mkdir -p /root/gocode/src/github.com/ProdriveTechnologies
WORKDIR /root/gocode/src/github.com/ProdriveTechnologies
RUN git clone https://github.com/ProdriveTechnologies/hpraid_exporter.git
WORKDIR /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter
COPY WORKSPACE /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/WORKSPACE
COPY BUILD.bazel /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/BUILD.bazel
RUN bazel build //...

FROM centos:7
WORKDIR /tmp
RUN curl -o ssacli.rpm https://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v123474/ssacli-2.60-19.0.x86_64.rpm
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install unzip && \
    yum localinstall -y --setopt=tsflags=nodocs ssacli.rpm && \
    yum clean all
RUN rm -rf ssacli.rpm

COPY --from=exp-builder /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/bazel-bin/linux_amd64_pure_stripped/hpraid_exporter /sbin/hpraid_exporter

ENTRYPOINT ["/sbin/hpraid_exporter"]
