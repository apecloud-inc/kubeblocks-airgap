FROM scratch
COPY charts charts
COPY registry registry
ENV NEBULA_HELM_OPTS=${NEBULA_HELM_OPTS:-""}
CMD ["helm upgrade --install kb-addon-nebula charts/nebula --namespace kb-system --create-namespace $(NEBULA_HELM_OPTS)"]