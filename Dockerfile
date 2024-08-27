FROM debian:12-slim AS downloader
LABEL maintainer="EKGF <info@ekgf.org>"

ARG TERRAFORM_VERSION="1.9.5"
ARG TERRAFORM_SOPS_VERSION="1.1.1"
ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get install -y curl wget unzip gpg lsb-release

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

RUN apt-get update && apt-get install -y terraform

RUN name="terraform-provider-sops_${TERRAFORM_SOPS_VERSION}" && \
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
LABEL maintainer="EKGF <info@ekgf.org>"
LABEL org.opencontainers.image.source="https://github.com/EKGF/gcloud-terraform"
LABEL org.opencontainers.image.description="Terraform Cloud Builder. This builder can be used to run the terraform tool in the GCE environment."
LABEL org.opencontainers.image.licenses=MIT

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

