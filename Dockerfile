FROM alpine:3.14 as downloader

ARG TERRAFORM_VERSION="1.0.11"
ARG TERRAFORM_VERSION_SHA256SUM="eeb46091a42dc303c3a3c300640c7774ab25cbee5083dafa5fd83b54c8aca664"
ARG TERRAFORM_SOPS_VERSION="0.6.3"

RUN apk --no-cache add curl unzip

RUN file="terraform_${TERRAFORM_VERSION}_linux_amd64.zip" ; \
    url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}" ; \
    wget "${url}/${file}" && \
    echo "${TERRAFORM_VERSION_SHA256SUM}  ${file}" > checksum && sha256sum -c checksum && \
    unzip ${file} -d /usr/bin && rm -f "${file}" && ls -al /usr/bin/terraform && \
    name="terraform-provider-sops_${TERRAFORM_SOPS_VERSION}" && \
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

