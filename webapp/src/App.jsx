import { useMemo, useState } from "react";

import { Button } from "./components/ui/button";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:5000";

const initialMessages = [
  {
    role: "assistant",
    content:
      "Hi! I'm your CraveBalance AI. What are you craving today?"
  }
];

function MessageBubble({ role, content }) {
  const isUser = role === "user";
  return (
    <div
      className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${
        isUser
          ? "self-end bg-brand-500 text-white"
          : "self-start bg-slate-900/70 text-slate-200"
      }`}
    >
      {content}
    </div>
  );
}

function LoadingDots() {
  return (
    <div className="flex items-center gap-2 rounded-2xl bg-slate-900/70 px-4 py-3 text-sm text-slate-200">
      <span className="h-2 w-2 animate-bounce rounded-full bg-brand-200" />
      <span className="h-2 w-2 animate-bounce rounded-full bg-brand-200 [animation-delay:120ms]" />
      <span className="h-2 w-2 animate-bounce rounded-full bg-brand-200 [animation-delay:240ms]" />
      <span className="text-xs text-slate-400">Thinking...</span>
    </div>
  );
}

export default function App() {
  const [token, setToken] = useState("");
  const [authMode, setAuthMode] = useState("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [authError, setAuthError] = useState(null);
  const [messages, setMessages] = useState(initialMessages);
  const [chatInput, setChatInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [stage, setStage] = useState("awaiting_crave");
  const [pendingCrave, setPendingCrave] = useState("");
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [sessionId, setSessionId] = useState(null);
  const [options, setOptions] = useState([]);
  const [selectedOption, setSelectedOption] = useState("");
  const [estimatedCalories, setEstimatedCalories] = useState(null);
  const [sessionTypes, setSessionTypes] = useState([]);
  const [challenges, setChallenges] = useState([]);
  const [createdChallenge, setCreatedChallenge] = useState(null);
  const [challengeId, setChallengeId] = useState(null);
  const [completionInput, setCompletionInput] = useState("75");
  const [error, setError] = useState(null);

  const headers = useMemo(() => {
    if (!token.trim()) {
      return { "Content-Type": "application/json" };
    }
    return {
      "Content-Type": "application/json",
      Authorization: token.startsWith("Bearer ") ? token : `Bearer ${token}`
    };
  }, [token]);

  const pushMessage = (role, content) => {
    setMessages((prev) => [...prev, { role, content }]);
  };

  const resetFlow = () => {
    setMessages(initialMessages);
    setChatInput("");
    setStage("awaiting_crave");
    setPendingCrave("");
    setLatitude(null);
    setLongitude(null);
    setSessionId(null);
    setOptions([]);
    setSelectedOption("");
    setEstimatedCalories(null);
    setSessionTypes([]);
    setChallenges([]);
    setCreatedChallenge(null);
    setChallengeId(null);
    setCompletionInput("75");
    setError(null);
  };

  const requestBrowserLocation = () =>
    new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error("Geolocation is not supported by this browser."));
        return;
      }
      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            lat: position.coords.latitude,
            lng: position.coords.longitude
          });
        },
        (error) => {
          reject(error);
        },
        { enableHighAccuracy: true, timeout: 10000 }
      );
    });

  const handleAuthSubmit = async () => {
    setLoading(true);
    setAuthError(null);

    try {
      const payload = { email, password };
      if (authMode === "signup") {
        payload.name = name;
      }

      const response = await fetch(`${API_URL}/auth/${authMode}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Authentication failed.");
      }

      const accessToken = data?.data?.session?.access_token;
      if (!accessToken) {
        throw new Error("No access token returned.");
      }

      setToken(accessToken);
      resetFlow();
    } catch (err) {
      setAuthError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    setToken("");
    setEmail("");
    setPassword("");
    setName("");
    resetFlow();
  };

  const handleCraveSubmit = async ({ craveItem, lat, lng }) => {
    setLoading(true);
    setError(null);
    pushMessage("assistant", "Looking for nearby options...");

    try {
      const response = await fetch(`${API_URL}/session/crave`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          crave_item: craveItem,
          latitude: Number(lat),
          longitude: Number(lng)
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to create session.");
      }

      setSessionId(data.data.session_id);
      setOptions(data.data.options || []);

      pushMessage(
        "assistant",
        `Here are ${data.data.options?.length || 0} options. Reply with the option number or click one below.`
      );
      setStage("awaiting_option");
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleOptionSelect = async (option) => {
    if (!sessionId) return;
    setLoading(true);
    setError(null);
    setSelectedOption(option);
    pushMessage("assistant", "Estimating calories...");

    try {
      const response = await fetch(`${API_URL}/session/select`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          session_id: sessionId,
          selected_option: option
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to select option.");
      }

      setEstimatedCalories(data.data.estimated_calories);
      setSessionTypes(data.data.session_types || []);

      pushMessage(
        "assistant",
        `Estimated calories: ${data.data.estimated_calories}. Choose a session type.`
      );
      setStage("awaiting_session_type");
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleSessionType = async (type) => {
    if (!sessionId) return;
    setLoading(true);
    setError(null);
    pushMessage("assistant", "Generating challenges...");

    try {
      const response = await fetch(`${API_URL}/session/choose-type`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          session_id: sessionId,
          session_type: type
        })
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to choose session type.");
      }

      if (type === "solo_challenge") {
        setChallenges(data.data.challenges || []);
        pushMessage(
          "assistant",
          "Pick a challenge to create. Reply with the number or click one below."
        );
        setStage("awaiting_challenge");
      } else {
        pushMessage("assistant", data.data.message || "Session updated.");
        setStage("awaiting_challenge");
      }
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleChallengeSelect = async (challenge) => {
    if (!sessionId) return;
    setLoading(true);
    setError(null);
    pushMessage("assistant", "Creating your challenge...");

    try {
      const response = await fetch(`${API_URL}/challenge/select`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          session_id: sessionId,
          challenge_description: challenge.description,
          time_limit: challenge.time_limit
        })
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to create challenge.");
      }

      setChallengeId(data.data.challenge_id);
      setCreatedChallenge({
        challenge_id: data.data.challenge_id,
        challenge: data.data.challenge,
        time_limit: data.data.time_limit,
        expiry_time: data.data.expiry_time,
        status: data.data.status
      });
      pushMessage(
        "assistant",
        `Challenge created. Time limit: ${data.data.time_limit} minutes. You can start it below.`
      );
      setStage("challenge_created");
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleChallengeStart = async () => {
    if (!challengeId) return;
    setLoading(true);
    setError(null);
    pushMessage("user", "Start challenge");

    try {
      const response = await fetch(`${API_URL}/challenge/start`, {
        method: "POST",
        headers,
        body: JSON.stringify({ challenge_id: challengeId })
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to start challenge.");
      }
      pushMessage("assistant", "Challenge started. Complete it and report your progress.");
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleChallengeComplete = async (percentage) => {
    if (!challengeId) return;
    setLoading(true);
    setError(null);
    pushMessage("user", `Completion: ${percentage}%`);

    try {
      const response = await fetch(`${API_URL}/challenge/complete`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          challenge_id: challengeId,
          completion_percentage: percentage
        })
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || "Failed to complete challenge.");
      }

      pushMessage(
        "assistant",
        `Rating ${data.data.rating}/10. Points: ${data.data.points_earned}. Total: ${data.data.total_points}. Rank: ${data.data.rank}.`
      );
    } catch (err) {
      setError(err.message);
      pushMessage("assistant", `Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const optionLabel = (option) => `${option.option} from ${option.store}`;

  const parseLocation = (text) => {
    const parts = text.split(",").map((value) => value.trim());
    if (parts.length !== 2) return null;
    const lat = Number(parts[0]);
    const lng = Number(parts[1]);
    if (Number.isNaN(lat) || Number.isNaN(lng)) return null;
    return { lat, lng };
  };

  const matchByIndex = (text, list) => {
    const num = Number(text);
    if (Number.isNaN(num)) return null;
    const index = num - 1;
    if (index < 0 || index >= list.length) return null;
    return list[index];
  };

  const handleSend = async () => {
    const trimmed = chatInput.trim();
    if (!trimmed || loading) return;
    setChatInput("");
    pushMessage("user", trimmed);

    if (stage === "awaiting_crave") {
      setPendingCrave(trimmed);
      pushMessage("assistant", "Requesting your location...");
      setStage("awaiting_location");
      try {
        setLoading(true);
        const location = await requestBrowserLocation();
        setLatitude(location.lat);
        setLongitude(location.lng);
        pushMessage(
          "assistant",
          `Got it. Using lat ${location.lat.toFixed(4)}, lng ${location.lng.toFixed(4)}.`
        );
        await handleCraveSubmit({
          craveItem: trimmed,
          lat: location.lat,
          lng: location.lng
        });
      } catch (err) {
        pushMessage(
          "assistant",
          "Location permission denied or unavailable. Please type your location as `lat, lng`."
        );
      } finally {
        setLoading(false);
      }
      return;
    }

    if (stage === "awaiting_location") {
      const parsed = parseLocation(trimmed);
      if (!parsed) {
        pushMessage(
          "assistant",
          "Please send your location in `lat, lng` format (example: `6.9271, 79.8612`)."
        );
        return;
      }
      setLatitude(parsed.lat);
      setLongitude(parsed.lng);
      await handleCraveSubmit({ craveItem: pendingCrave, lat: parsed.lat, lng: parsed.lng });
      return;
    }

    if (stage === "awaiting_option") {
      const matched = matchByIndex(trimmed, options);
      const choice = matched ? optionLabel(matched) : trimmed;
      const option = matched || options.find((item) => {
        const label = optionLabel(item).toLowerCase();
        return label.includes(trimmed.toLowerCase());
      });
      if (!option) {
        pushMessage("assistant", "Please pick one of the listed options.");
        return;
      }
      await handleOptionSelect(choice);
      return;
    }

    if (stage === "awaiting_session_type") {
      const normalized = trimmed.toLowerCase().replace(/\s+/g, "_");
      const selected = sessionTypes.find((type) => type === normalized);
      if (!selected) {
        pushMessage("assistant", "Please choose a valid session type from the list.");
        return;
      }
      await handleSessionType(selected);
      return;
    }

    if (stage === "awaiting_challenge") {
      const matched = matchByIndex(trimmed, challenges);
      const challenge = matched || challenges.find((item) => {
        const label = item.description.toLowerCase();
        return label.includes(trimmed.toLowerCase());
      });
      if (!challenge) {
        pushMessage("assistant", "Please pick a challenge from the list.");
        return;
      }
      await handleChallengeSelect(challenge);
      return;
    }

    if (stage === "challenge_created") {
      pushMessage(
        "assistant",
        "Your challenge is ready. Use the controls below to start or complete it."
      );
    }
  };

  return (
    <div className="min-h-screen gradient-bg">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 px-6 py-10">
        <header className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="grid h-12 w-12 place-items-center rounded-2xl bg-brand-500/20 text-brand-200 font-semibold">
                CB
              </div>
              <div>
                <p className="text-lg font-semibold text-white">CraveBalance</p>
                <p className="text-sm text-slate-400">
                  Guided craving flow based on the backend session endpoints
                </p>
              </div>
            </div>
            {token && (
              <Button variant="outline" size="sm" onClick={handleLogout}>
                Log out
              </Button>
            )}
          </div>
        </header>

        {!token ? (
          <section className="mx-auto flex w-full max-w-lg flex-col gap-6 rounded-3xl border border-slate-800 bg-slate-950/60 p-8 shadow-soft">
            <div className="space-y-2 text-center">
              <p className="text-sm uppercase text-brand-200">
                {authMode === "login" ? "Welcome back" : "Create account"}
              </p>
              <h1 className="text-2xl font-semibold text-white">
                {authMode === "login" ? "Log in" : "Sign up"} to start a craving session
              </h1>
              <p className="text-sm text-slate-400">
                Access tokens are pulled from Supabase auth responses.
              </p>
            </div>

            {authMode === "signup" && (
              <div className="flex flex-col gap-2">
                <label className="text-xs uppercase text-slate-500">Name</label>
                <input
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  placeholder="Jane Doe"
                  className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                />
              </div>
            )}

            <div className="flex flex-col gap-2">
              <label className="text-xs uppercase text-slate-500">Email</label>
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@example.com"
                className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs uppercase text-slate-500">Password</label>
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="••••••••"
                className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
              />
            </div>

            <Button size="lg" onClick={handleAuthSubmit} disabled={loading}>
              {loading
                ? "Working..."
                : authMode === "login"
                ? "Log in"
                : "Create account"}
            </Button>

            {authError && (
              <div className="rounded-xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-sm text-rose-200">
                {authError}
              </div>
            )}

            <div className="text-center text-sm text-slate-400">
              {authMode === "login" ? "New here?" : "Already have an account?"} {" "}
              <button
                type="button"
                onClick={() => setAuthMode(authMode === "login" ? "signup" : "login")}
                className="text-brand-200 hover:text-brand-100"
              >
                {authMode === "login" ? "Create one" : "Log in"}
              </button>
            </div>
          </section>
        ) : (
          <div className="grid gap-8 lg:grid-cols-[1.3fr_0.7fr]">
            <section className="flex flex-col gap-4 rounded-3xl border border-slate-800 bg-slate-950/60 p-6 shadow-soft">
              <p className="text-xs uppercase text-slate-500">Conversation</p>
              <div className="flex max-h-[520px] flex-col gap-3 overflow-y-auto rounded-2xl border border-slate-800 bg-slate-900/40 p-4">
                {messages.map((message, index) => (
                  <MessageBubble key={`${message.role}-${index}`} {...message} />
                ))}
                {loading && <LoadingDots />}
              </div>

              {error && (
                <div className="rounded-xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-sm text-rose-200">
                  {error}
                </div>
              )}

              {stage === "awaiting_option" && options.length > 0 && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Options</p>
                  <div className="grid gap-3">
                    {options.map((option, index) => (
                      <button
                        key={`${option.option}-${option.store}`}
                        onClick={() => handleOptionSelect(optionLabel(option))}
                        className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4 text-left transition hover:border-brand-500"
                      >
                        <p className="text-xs text-slate-500">Option {index + 1}</p>
                        <p className="text-sm font-semibold text-white">{option.option}</p>
                        <p className="text-xs text-slate-400">{option.store}</p>
                        <p className="mt-2 text-xs text-slate-400">{option.description}</p>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {stage === "awaiting_session_type" && sessionTypes.length > 0 && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Session Types</p>
                  <div className="flex flex-wrap gap-2">
                    {sessionTypes.map((type) => (
                      <Button
                        key={type}
                        variant={type === "solo_challenge" ? "default" : "outline"}
                        size="sm"
                        onClick={() => handleSessionType(type)}
                      >
                        {type.replace("_", " ")}
                      </Button>
                    ))}
                  </div>
                </div>
              )}

              {stage === "awaiting_challenge" && challenges.length > 0 && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Challenges</p>
                  <div className="grid gap-3">
                    {challenges.map((challenge, index) => (
                      <button
                        key={challenge.description}
                        onClick={() => handleChallengeSelect(challenge)}
                        className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4 text-left transition hover:border-brand-500"
                      >
                        <p className="text-xs text-slate-500">Challenge {index + 1}</p>
                        <p className="text-sm font-semibold text-white">
                          {challenge.description}
                        </p>
                        <p className="text-xs text-slate-400">
                          Time limit: {challenge.time_limit} minutes
                        </p>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex gap-3">
                <input
                  value={chatInput}
                  onChange={(event) => setChatInput(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      handleSend();
                    }
                  }}
                  placeholder={
                    stage === "awaiting_crave"
                      ? "Type your craving..."
                      : stage === "awaiting_location"
                      ? "If prompted, allow location or type lat, lng"
                      : "Type your reply..."
                  }
                  className="w-full rounded-2xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                />
                <Button size="lg" onClick={handleSend} disabled={loading}>
                  {loading ? "..." : "Send"}
                </Button>
              </div>
            </section>

            <section className="flex flex-col gap-4 rounded-3xl border border-slate-800 bg-slate-950/60 p-6 shadow-soft">
              <p className="text-xs uppercase text-slate-500">Challenge</p>

              {createdChallenge ? (
                <div className="space-y-4">
                  <div className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4">
                    <p className="text-sm font-semibold text-white">{createdChallenge.challenge}</p>
                    <p className="text-xs text-slate-400">
                      Time limit: {createdChallenge.time_limit} minutes
                    </p>
                    <p className="text-xs text-slate-500">Status: {createdChallenge.status}</p>
                  </div>

                  <Button size="sm" onClick={handleChallengeStart} disabled={loading}>
                    Start Challenge
                  </Button>

                  <div className="space-y-2">
                    <label className="text-xs uppercase text-slate-500">
                      Completion Percentage
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        min="0"
                        max="100"
                        value={completionInput}
                        onChange={(event) => setCompletionInput(event.target.value)}
                        className="w-full rounded-2xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                      />
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleChallengeComplete(Number(completionInput))}
                        disabled={loading}
                      >
                        Submit
                      </Button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="rounded-2xl border border-dashed border-slate-800 p-4 text-sm text-slate-400">
                  Create a challenge through the chat to see it here.
                </div>
              )}
            </section>
          </div>
        )}
      </div>
    </div>
  );
}
