FROM alpine:3.9 as downloader

ARG TERRAFORM_VERSION="0.12.25"
ARG TERRAFORM_VERSION_SHA256SUM="e95daabd1985329f87e6d40ffe7b9b973ff0abc07a403f767e8658d64d733fb0"
ARG TERRAFORM_SOPS_VERSION="0.5.0"

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
    pwd && ls -al

#
# Final dockerfile stage
#
FROM gcr.io/cloud-builders/gcloud:latest

#
# Current user is root with home /root
#
WORKDIR /root

COPY --from=downloader /downloader/sops/terraform-provider-sops* ./.terraform.d/plugins/linux_amd64/
COPY --from=downloader /usr/bin/terraform /usr/bin/terraform
COPY entrypoint.sh ./entrypoint.sh
RUN ls -al; chmod -v +x ./entrypoint.sh ; ls -al

#
# Provide the following environment variables when you run the container:
#
#ENV TF_VAR_project-name=yourprojectid
#ENV TF_VAR_region=yourregion
#ENV _BUCKET=yourbucket
#ENV _INFRA_DIR=infrastructure
#ENV GCLOUD_SERVICE_KEY="<base64 encoded service account key file>

ENTRYPOINT ["/root/entrypoint.sh"]

