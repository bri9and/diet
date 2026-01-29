import Link from "next/link";

export default function Home() {
  return (
    <div style={{
      minHeight: "100vh",
      background: "linear-gradient(180deg, #f0fdf4 0%, #ffffff 50%, #ffffff 100%)",
      fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    }}>
      {/* Header */}
      <header style={{
        padding: "1.5rem 2rem",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        maxWidth: "1200px",
        margin: "0 auto"
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
          <img
            src="/logo.png"
            alt="Fuelvio"
            style={{
              width: "40px",
              height: "40px",
              borderRadius: "10px"
            }}
          />
          <span style={{ fontWeight: 700, fontSize: "1.25rem", color: "#111" }}>Fuelvio</span>
        </div>
      </header>

      {/* Hero Section */}
      <main style={{
        maxWidth: "1200px",
        margin: "0 auto",
        padding: "4rem 2rem 6rem"
      }}>
        <div style={{ textAlign: "center", maxWidth: "800px", margin: "0 auto" }}>
          {/* Badge */}
          <div style={{
            display: "inline-block",
            padding: "0.5rem 1rem",
            background: "#dcfce7",
            borderRadius: "100px",
            color: "#166534",
            fontSize: "0.875rem",
            fontWeight: 500,
            marginBottom: "1.5rem"
          }}>
            AI-Powered Nutrition Tracking
          </div>

          {/* Headline */}
          <h1 style={{
            fontSize: "clamp(2.5rem, 5vw, 4rem)",
            fontWeight: 700,
            lineHeight: 1.1,
            color: "#111",
            marginBottom: "1.5rem"
          }}>
            Track your nutrition<br />
            <span style={{ color: "#22c55e" }}>effortlessly</span>
          </h1>

          {/* Subheadline */}
          <p style={{
            fontSize: "1.25rem",
            color: "#666",
            lineHeight: 1.6,
            marginBottom: "2.5rem",
            maxWidth: "600px",
            margin: "0 auto 2.5rem"
          }}>
            Snap a photo of your meal and let AI do the rest.
            Get instant nutritional insights and reach your health goals faster.
          </p>

          {/* CTA Buttons */}
          <div style={{
            display: "flex",
            gap: "1rem",
            justifyContent: "center",
            flexWrap: "wrap"
          }}>
            <a
              href="#"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "0.5rem",
                padding: "1rem 2rem",
                background: "linear-gradient(135deg, #22c55e 0%, #16a34a 100%)",
                color: "white",
                borderRadius: "12px",
                fontWeight: 600,
                fontSize: "1rem",
                textDecoration: "none",
                boxShadow: "0 4px 14px rgba(34, 197, 94, 0.4)",
                transition: "transform 0.2s, box-shadow 0.2s"
              }}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.09997 22C7.78997 22.05 6.79997 20.68 5.95997 19.47C4.24997 17 2.93997 12.45 4.69997 9.39C5.56997 7.87 7.12997 6.91 8.81997 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"/>
              </svg>
              Download for iOS
            </a>
          </div>

          {/* App Preview Placeholder */}
          <div style={{
            marginTop: "4rem",
            padding: "2rem",
            background: "white",
            borderRadius: "24px",
            boxShadow: "0 20px 50px rgba(0, 0, 0, 0.1)",
            maxWidth: "320px",
            margin: "4rem auto 0"
          }}>
            <div style={{
              width: "100%",
              aspectRatio: "9/16",
              background: "linear-gradient(180deg, #f0fdf4 0%, #dcfce7 100%)",
              borderRadius: "16px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexDirection: "column",
              gap: "1rem"
            }}>
              <img
                src="/logo.png"
                alt="Fuelvio App"
                style={{
                  width: "100px",
                  height: "100px",
                  borderRadius: "24px"
                }}
              />
              <p style={{ color: "#166534", fontWeight: 600 }}>Coming Soon</p>
            </div>
          </div>
        </div>

        {/* Features Section */}
        <section style={{
          marginTop: "6rem",
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
          gap: "2rem",
          maxWidth: "1000px",
          margin: "6rem auto 0"
        }}>
          <FeatureCard
            icon="📸"
            title="Photo Recognition"
            description="Snap a photo of your meal. Our AI instantly identifies foods and calculates nutrition."
          />
          <FeatureCard
            icon="🎯"
            title="Personalized Goals"
            description="Get custom calorie and macro targets based on your body and goals."
          />
          <FeatureCard
            icon="📊"
            title="Track Progress"
            description="See your nutrition trends over time with beautiful charts and insights."
          />
        </section>

        {/* Footer */}
        <footer style={{
          marginTop: "6rem",
          textAlign: "center",
          color: "#999",
          fontSize: "0.875rem"
        }}>
          <p>&copy; 2026 Fuelvio. All rights reserved.</p>
          <div style={{ marginTop: "0.5rem", display: "flex", gap: "1.5rem", justifyContent: "center" }}>
            <a href="#" style={{ color: "#666", textDecoration: "none" }}>Privacy Policy</a>
            <a href="#" style={{ color: "#666", textDecoration: "none" }}>Terms of Service</a>
          </div>
        </footer>
      </main>
    </div>
  );
}

function FeatureCard({ icon, title, description }: { icon: string; title: string; description: string }) {
  return (
    <div style={{
      padding: "2rem",
      background: "white",
      borderRadius: "16px",
      boxShadow: "0 4px 20px rgba(0, 0, 0, 0.05)",
      border: "1px solid #f0f0f0"
    }}>
      <div style={{
        width: "48px",
        height: "48px",
        borderRadius: "12px",
        background: "#f0fdf4",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: "24px",
        marginBottom: "1rem"
      }}>
        {icon}
      </div>
      <h3 style={{
        fontSize: "1.125rem",
        fontWeight: 600,
        color: "#111",
        marginBottom: "0.5rem"
      }}>
        {title}
      </h3>
      <p style={{
        color: "#666",
        lineHeight: 1.6,
        fontSize: "0.95rem"
      }}>
        {description}
      </p>
    </div>
  );
}
