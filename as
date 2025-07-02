import * as React from "react"
import { useState, useEffect } from "react"
import { addPropertyControls, ControlType } from "framer"

export function VivHost({ restaurantId, route }) {
    const [input, setInput] = useState("")
    const [response, setResponse] = useState("")
    const [loading, setLoading] = useState(false)
    const [messages, setMessages] = useState([]) // Track conversation history
    const [displayedResponse, setDisplayedResponse] = useState("")

    // Typewriter effect for assistant response
    useEffect(() => {
        let i = 0
        if (response && !loading) {
            setDisplayedResponse("")
            const interval = setInterval(() => {
                setDisplayedResponse((prev) => prev + response.charAt(i))
                i++
                if (i >= response.length) clearInterval(interval)
            }, 20)
            return () => clearInterval(interval)
        }
    }, [response, loading])

    const handleSend = async () => {
        if (!input.trim()) return
        setLoading(true)
        setResponse("")
        const updatedMessages = [...messages, { role: "user", content: input }]
        setMessages(updatedMessages)

        let requestBody
        if (route === "askAI") {
            requestBody = {
                restaurantId,
                route,
                conversationHistory: updatedMessages,
            }
        } else {
            let userMessage
            try {
                const parsed = JSON.parse(input)
                if (typeof parsed === "object" && parsed !== null && !Array.isArray(parsed)) {
                    userMessage = parsed
                } else {
                    userMessage = input
                }
            } catch {
                userMessage = input
            }
            requestBody = { userMessage, route, restaurantId }
        }

        try {
            const res = await fetch("https://lnkd.in/gAmeZnNX", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(requestBody),
            })

            const data = await res.json()
            const r = data.middlewareResponse

            if (r?.confirmationCode && r?.name) {
                const warmReply = `Thanks ${r.name}! Your table for ${r.partySize} is confirmed at ${r.timeSlot} on ${r.date}. Your confirmation code is ${r.confirmationCode}. We look forward to seeing you!`
                setResponse(warmReply)
                setMessages([])
            } else if (typeof r === "string") {
                setMessages((prev) => [...prev, { role: "assistant", content: r }])
                setResponse(r)
            } else if (r?.message) {
                setMessages((prev) => [...prev, { role: "assistant", content: r.message }])
                setResponse(r.message)
            } else {
                setResponse("✅ Request complete.")
            }
        } catch (err) {
            setResponse("❌ Something went wrong. Please try again.")
            console.error(err)
        }

        setInput("")
        setLoading(false)
    }

    return (
        <div style={{ width: "100%", padding: 20, fontFamily: "sans-serif" }}>
            <div style={{ minHeight: 300, marginBottom: 20 }}>
                {messages.map((msg, index) => (
                    <div
                        key={index}
                        style={{
                            margin: "10px 0",
                            padding: "10px 15px",
                            borderRadius: 10,
                            backgroundColor: msg.role === "user" ? "#e0e0e0" : "#f5f5f5",
                            textAlign: msg.role === "user" ? "right" : "left",
                            whiteSpace: "pre-wrap",
                        }}
                    >
                        {msg.content}
                    </div>
                ))}
                {loading && (
                    <div style={{ padding: "10px 15px", opacity: 0.6 }}>
                        <span style={{
                            display: "inline-block",
                            width: 10,
                            height: 10,
                            borderRadius: "50%",
                            background: "#aaa",
                            animation: "pulse 1s infinite"
                        }} />
                        <span style={{ marginLeft: 10 }}>Viv is thinking…</span>
                    </div>
                )}
                {!loading && displayedResponse && (
                    <div
                        style={{
                            marginTop: 10,
                            padding: "10px 15px",
                            backgroundColor: "#f5f5f5",
                            borderRadius: 10,
                            whiteSpace: "pre-wrap",
                        }}
                    >
                        {displayedResponse}
                    </div>
                )}
            </div>

            <textarea
                rows={5}
                placeholder="Hi Viv! I'd like a table for 2 at 7pm tonight."
                style={{
                    width: "100%",
                    padding: 10,
                    borderRadius: 8,
                    fontSize: 18,
                    border: "1px solid #ccc",
                    resize: "none",
                }}
                value={input}
                onChange={(e) => setInput(e.target.value)}
            />
            <button
                style={{
                    marginTop: 10,
                    padding: "10px 20px",
                    borderRadius: 8,
                    background: "#000",
                    color: "#fff",
                    border: "none",
                    cursor: "pointer",
                }}
                onClick={handleSend}
                disabled={loading}
            >
                {loading ? "Sending..." : "Send"}
            </button>

            <style>
                {`
                    @keyframes pulse {
                        0% { transform: scale(1); opacity: 1; }
                        50% { transform: scale(1.3); opacity: 0.6; }
                        100% { transform: scale(1); opacity: 1; }
                    }
                `}
            </style>
        </div>
    )
}

addPropertyControls(VivHost, {
    restaurantId: {
        type: ControlType.String,
        title: "Restaurant ID",
        defaultValue: "mollyscafe1",
    },
    route: {
        type: ControlType.Enum,
        options: ["reservation", "changeReservation", "cancelReservation", "checkAvailability", "askAI"],
        optionTitles: ["Reservation", "Change", "Cancel", "Check Availability", "Ask Viv AI"],
        defaultValue: "reservation",
    },
})
