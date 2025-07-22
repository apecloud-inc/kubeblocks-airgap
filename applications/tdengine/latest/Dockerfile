FROM scratch
COPY charts charts
COPY registry registry
ENV TDENGINE_HELM_OPTS=${TDENGINE_HELM_OPTS:-""}
CMD ["helm upgrade --install kb-addon-tdengine charts/tdengine --namespace kb-system --create-namespace $(TDENGINE_HELM_OPTS)"]