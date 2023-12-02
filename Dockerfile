FROM public.ecr.aws/amazonlinux/amazonlinux:2023 as builder

# We need the full version of GnuPG
RUN dnf install -y --allowerasing wget gnupg2

RUN MP_ARCH=`uname -p | sed s/aarch64/arm64/` && \
    wget -q "https://s3.amazonaws.com/mountpoint-s3-release/latest/$MP_ARCH/mount-s3.rpm" && \
    wget -q "https://s3.amazonaws.com/mountpoint-s3-release/latest/$MP_ARCH/mount-s3.rpm.asc" && \
    wget -q https://s3.amazonaws.com/mountpoint-s3-release/public_keys/KEYS

# Import the key and validate it has the fingerprint we expect
RUN gpg --import KEYS && \
    (gpg --fingerprint mountpoint-s3@amazon.com | grep "673F E406 1506 BB46 9A0E  F857 BE39 7A52 B086 DA5A")

# Verify the downloaded binary
RUN gpg --verify mount-s3.rpm.asc

# Node.js binary verification instructions: https://github.com/nodejs/node?tab=readme-ov-file#verifying-binaries
ARG NODE_VERSION=20.9.0
RUN wget --quiet https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz \
    && wget --quiet https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt{,.sig} \
    && gpg --keyserver hkps://keys.openpgp.org --recv-keys C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    && gpg --verify SHASUMS256.txt{.sig,} \
    && grep node-v${NODE_VERSION}-linux-x64.tar.xz SHASUMS256.txt | sha256sum -c - \
    && rm -f SHASUMS256.txt{,.sig} \
    && mv node-v${NODE_VERSION}-linux-x64.tar.xz node.tar.xz

FROM amazonlinux:2023
COPY --from=builder /mount-s3.rpm /mount-s3.rpm

RUN dnf upgrade -y && \
    dnf install -y ./mount-s3.rpm && \
    dnf clean all && \
    rm mount-s3.rpm

RUN dnf upgrade -y \
    && dnf install -y python3-pip

RUN pip install supervisor

COPY --from=builder /node.tar.xz /node.tar.xz
RUN dnf upgrade -y \
    && dnf install -y tar xz \
    && tar -xf /node.tar.xz -C /usr/local --strip-components=1 \
    && rm /node.tar.xz

RUN npm install -g serve

COPY ./serve.json /etc/serve.json
COPY ./supervisord.conf /etc/supervisord.conf

# Optional environment variables
ENV MOUNTPOINT_S3_ADDITIONAL_ARGS=""
ENV SERVE_ADDITIONAL_ARGS=""

# Run in foreground mode so that the container can be detached without exiting Mountpoint
ENTRYPOINT [ "supervisord" ]

