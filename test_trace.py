import os
from openinference.instrumentation.openai import OpenAIInstrumentor
from opentelemetry import trace as trace_api
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk import trace as trace_sdk
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from openai import OpenAI

# Configure OpenTelemetry to send traces to local Phoenix
endpoint = "http://localhost:6006/v1/traces"
tracer_provider = trace_sdk.TracerProvider()
tracer_provider.add_span_processor(SimpleSpanProcessor(OTLPSpanExporter(endpoint)))
trace_api.set_tracer_provider(tracer_provider)
OpenAIInstrumentor().instrument()

# We can just send a dummy span manually to test Phoenix!
tracer = trace_api.get_tracer("test-tracer")

with tracer.start_as_current_span("Antigravity-Test-Span") as span:
    span.set_attribute("llm.prompt_template.variables", "hello")
    span.set_attribute("message", "Ye ek test trace hai Antigravity ki taraf se!")
    print("Test trace sent successfully to Phoenix!")
