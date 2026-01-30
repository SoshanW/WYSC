import { useMemo, useState } from "react";

import { Button } from "./components/ui/button";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:5000";

const initialMessages = [
  {
    role: "assistant",
    content:
      "Hi! I'm your CraveBalance guide. Tell me what you're craving and share your location to get started."
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

export default function App() {
  const [token, setToken] = useState("");
  const [authMode, setAuthMode] = useState("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [authError, setAuthError] = useState(null);
  const [craveItem, setCraveItem] = useState("");
  const [latitude, setLatitude] = useState("6.9271");
  const [longitude, setLongitude] = useState("79.8612");
  const [messages, setMessages] = useState(initialMessages);
  const [loading, setLoading] = useState(false);
  const [sessionId, setSessionId] = useState(null);
  const [options, setOptions] = useState([]);
  const [selectedOption, setSelectedOption] = useState("");
  const [estimatedCalories, setEstimatedCalories] = useState(null);
  const [sessionTypes, setSessionTypes] = useState([]);
  const [challenges, setChallenges] = useState([]);
  const [challengeId, setChallengeId] = useState(null);
  const [error, setError] = useState(null);

  const canSubmitCrave = useMemo(() => {
    return token.trim() && craveItem.trim() && latitude && longitude && !loading;
  }, [token, craveItem, latitude, longitude, loading]);

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
      setMessages(initialMessages);
      setCraveItem("");
      setOptions([]);
      setSelectedOption("");
      setEstimatedCalories(null);
      setSessionTypes([]);
      setChallenges([]);
      setChallengeId(null);
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
    setMessages(initialMessages);
    setSessionId(null);
    setOptions([]);
    setSelectedOption("");
    setEstimatedCalories(null);
    setSessionTypes([]);
    setChallenges([]);
    setChallengeId(null);
  };

  const handleCraveSubmit = async () => {
    setLoading(true);
    setError(null);
    pushMessage("user", `Craving: ${craveItem} (lat: ${latitude}, lng: ${longitude})`);

    try {
      const response = await fetch(`${API_URL}/session/crave`, {
        method: "POST",
        headers,
        body: JSON.stringify({
          crave_item: craveItem,
          latitude: Number(latitude),
          longitude: Number(longitude)
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
        `Here are ${data.data.options?.length || 0} options. Pick one to estimate calories.`
      );
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
    pushMessage("user", `Select option: ${option}`);

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
    pushMessage("user", `Session type: ${type}`);

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
        pushMessage("assistant", "Pick a challenge to continue.");
      } else {
        pushMessage("assistant", data.data.message || "Session updated.");
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
    pushMessage("user", `Challenge: ${challenge.description}`);

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
      pushMessage(
        "assistant",
        `Challenge created. Time limit: ${data.data.time_limit} minutes. Start when ready.`
      );
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
          <div className="grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
            <section className="flex flex-col gap-4 rounded-3xl border border-slate-800 bg-slate-950/60 p-6 shadow-soft">
              <div className="flex flex-col gap-3">
                <label className="text-xs uppercase text-slate-500">Craving</label>
                <input
                  value={craveItem}
                  onChange={(event) => setCraveItem(event.target.value)}
                  placeholder="e.g. Chicken Cheese Kottu"
                  className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                />
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="flex flex-col gap-3">
                  <label className="text-xs uppercase text-slate-500">Latitude</label>
                  <input
                    value={latitude}
                    onChange={(event) => setLatitude(event.target.value)}
                    className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                  />
                </div>
                <div className="flex flex-col gap-3">
                  <label className="text-xs uppercase text-slate-500">Longitude</label>
                  <input
                    value={longitude}
                    onChange={(event) => setLongitude(event.target.value)}
                    className="w-full rounded-xl border border-slate-800 bg-slate-900/70 px-4 py-3 text-sm text-slate-200 outline-none focus:border-brand-500"
                  />
                </div>
              </div>

              <Button size="lg" disabled={!canSubmitCrave} onClick={handleCraveSubmit}>
                {loading ? "Working..." : "Start craving flow"}
              </Button>

              {error && (
                <div className="rounded-xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-sm text-rose-200">
                  {error}
                </div>
              )}
            </section>

            <section className="flex flex-col gap-4 rounded-3xl border border-slate-800 bg-slate-950/60 p-6 shadow-soft">
              <p className="text-xs uppercase text-slate-500">Conversation</p>
              <div className="flex max-h-[420px] flex-col gap-3 overflow-y-auto rounded-2xl border border-slate-800 bg-slate-900/40 p-4">
                {messages.map((message, index) => (
                  <MessageBubble key={`${message.role}-${index}`} {...message} />
                ))}
              </div>

              {options.length > 0 && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Options</p>
                  <div className="grid gap-3">
                    {options.map((option) => (
                      <button
                        key={`${option.option}-${option.store}`}
                        onClick={() =>
                          handleOptionSelect(`${option.option} from ${option.store}`)
                        }
                        className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4 text-left transition hover:border-brand-500"
                      >
                        <p className="text-sm font-semibold text-white">{option.option}</p>
                        <p className="text-xs text-slate-400">{option.store}</p>
                        <p className="mt-2 text-xs text-slate-400">{option.description}</p>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {selectedOption && estimatedCalories !== null && sessionTypes.length > 0 && (
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

              {challenges.length > 0 && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Challenges</p>
                  <div className="grid gap-3">
                    {challenges.map((challenge) => (
                      <button
                        key={challenge.description}
                        onClick={() => handleChallengeSelect(challenge)}
                        className="rounded-2xl border border-slate-800 bg-slate-900/70 p-4 text-left transition hover:border-brand-500"
                      >
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

              {challengeId && (
                <div className="space-y-3">
                  <p className="text-xs uppercase text-slate-500">Challenge Controls</p>
                  <div className="flex flex-wrap gap-2">
                    <Button size="sm" onClick={handleChallengeStart}>
                      Start Challenge
                    </Button>
                    {[25, 50, 75, 100].map((value) => (
                      <Button
                        key={value}
                        size="sm"
                        variant="outline"
                        onClick={() => handleChallengeComplete(value)}
                      >
                        {value}% complete
                      </Button>
                    ))}
                  </div>
                </div>
              )}
            </section>
          </div>
        )}
      </div>
    </div>
  );
}
