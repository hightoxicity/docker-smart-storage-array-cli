FROM centos:7 as exp-builder
WORKDIR /root
ENV COMMIT_HASH 76a6dd638038c39c1a3ecf6f41d462f0ec4cd8c0
RUN curl -o /etc/yum.repos.d/vbatts-bazel-epel-7.repo \
    https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo && \
    echo '4a73fc11148887d2c2ef48e18a939057fc26ecf9e71c02ed119ac7141c5a7ddd  /etc/yum.repos.d/vbatts-bazel-epel-7.repo' | sha256sum -c
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install bazel git
RUN yum -y --setopt=tsflags=nodocs groupinstall 'Development Tools'
RUN mkdir -p /root/gocode/bin /root/gocode/src \
    /root/gocode/src/github.com/ProdriveTechnologies
WORKDIR /root/gocode/src/github.com/ProdriveTechnologies
RUN git clone https://github.com/ProdriveTechnologies/hpraid_exporter.git
WORKDIR /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter
RUN git checkout ${COMMIT_HASH}
COPY WORKSPACE /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/WORKSPACE
COPY BUILD.bazel /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/BUILD.bazel
RUN bazel build //...

FROM centos:7
WORKDIR /tmp
RUN curl -o ssacli.rpm https://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v123474/ssacli-2.60-19.0.x86_64.rpm
RUN yum -y --setopt=tsflags=nodocs update && \
    yum localinstall -y --setopt=tsflags=nodocs ssacli.rpm && \
    yum clean all
RUN rm -rf ssacli.rpm

COPY --from=exp-builder /root/gocode/src/github.com/ProdriveTechnologies/hpraid_exporter/bazel-bin/linux_amd64_pure_stripped/hpraid_exporter /sbin/hpraid_exporter

ENTRYPOINT ["/sbin/hpraid_exporter"]
