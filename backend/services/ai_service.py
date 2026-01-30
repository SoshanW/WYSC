import asyncio
import os

try:
    from copilot import CopilotClient
except ImportError:  # pragma: no cover - handled at runtime
    CopilotClient = None


async def ask_copilot(prompt: str) -> str:
    if CopilotClient is None:
        raise RuntimeError(
            "Copilot SDK is not installed. Install it from the copilot-sdk repo."
        )

    client = CopilotClient()
    await client.start()
    session = await client.create_session({"model": os.getenv("COPILOT_MODEL", "gemini-3-pro")})

    done = asyncio.Event()
    response_text = {"value": ""}

    def on_event(event):
        if event.type.value == "assistant.message":
            response_text["value"] = event.data.content or ""
        elif event.type.value == "session.idle":
            done.set()

    session.on(on_event)
    await session.send({"prompt": prompt})
    await done.wait()

    await session.destroy()
    await client.stop()

    return response_text["value"]
