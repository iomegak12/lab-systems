#
# OTLP / Observability lab - pinned versions (single source of truth)
#
# Read by:
#   install-lab-software-otlp.ps1   (pulls images, downloads Java agent)
#   installation-check.ps1 -Otlp    (verifies images and Java agent)
#
# To bump a version, change it here only. Never use ':latest' - the lab must be
# reproducible between preparation day and session day.
#
@{
    # https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases
    JavaAgentVersion = 'v2.31.1'

    # Folder where lab tools (Java agent jar) are placed
    ToolsDirectory   = 'C:\otlp-lab\tools'

    # Docker images pre-pulled for the lab (order = pull order)
    Images           = @(
        @{ Name = 'OTel Collector (contrib)'; Ref = 'otel/opentelemetry-collector-contrib:0.161.0'; Ports = '4317 (OTLP gRPC), 4318 (OTLP HTTP)' }
        @{ Name = 'telemetrygen';             Ref = 'ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.161.0'; Ports = '-' }
        @{ Name = 'Prometheus';               Ref = 'prom/prometheus:v3.15.0'; Ports = '9090' }
        @{ Name = 'Grafana';                  Ref = 'grafana/grafana:13.2.2'; Ports = '3000' }
        @{ Name = 'Loki';                     Ref = 'grafana/loki:3.7.8'; Ports = '3100' }
        @{ Name = 'Tempo';                    Ref = 'grafana/tempo:3.0.3'; Ports = '3200' }
        @{ Name = 'Jaeger (v2 all-in-one)';   Ref = 'jaegertracing/jaeger:2.21.0'; Ports = '16686 (UI)' }
    )
}
