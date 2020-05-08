FROM alpine:3.9 as downloader

ARG TERRAFORM_VERSION=0.12.15
ARG TERRAFORM_VERSION_SHA256SUM="2acb99936c32f04d0779c3aba3552d6d2a1fa32ed63cbca83a84e58714f22022"
ARG TERRAFORM_SOPS_VERSION=0.5.0

RUN apk --no-cache add curl unzip

RUN file="terraform_${TERRAFORM_VERSION}_linux_amd64.zip" ; \
    url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}" ; \
    wget "${url}/${file}" && \
    echo "${TERRAFORM_VERSION_SHA256SUM}  ${file}" > checksum && sha256sum -c checksum && \
    unzip ${file} -d /usr/bin && rm -f "${file}" && ls -al /usr/bin/terraform && \
    name="terraform-provider-sops_v${TERRAFORM_SOPS_VERSION}" && \
    url="https://github.com/carlpett/terraform-provider-sops/releases/download/v${TERRAFORM_SOPS_VERSION}" && \
    url="${url}/${name}_linux_amd64.zip" && \
    echo "Downloading ${name} from ${url}" >&2 && \
    curl -L ${url} > /tmp/sops.zip && \
    mkdir -p /downloader/sops && cd /downloader/sops && unzip /tmp/sops.zip && \
    mv -v "${name}" terraform-provider-sops && ls -al

#
# Final dockerfile stage
#
FROM gcr.io/cloud-builders/gcloud

COPY --from=downloader /downloader/sops/terraform-provider-sops /root/.terraform.d/plugins/
COPY --from=downloader /usr/bin/terraform /usr/bin/terraform
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod u+x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
