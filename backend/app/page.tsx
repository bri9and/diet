export default function Home() {
  return (
    <div style={{ padding: "2rem" }}>
      <h1>Diet App API</h1>
      <p style={{ marginTop: "1rem", color: "#666" }}>
        Backend API server for the Diet App iOS application.
      </p>
      <h2 style={{ marginTop: "2rem" }}>Available Endpoints</h2>
      <ul style={{ marginTop: "1rem", marginLeft: "1.5rem" }}>
        <li>
          <code>GET /api/health</code> - Health check
        </li>
        <li>
          <code>GET /api/users/me</code> - Get current user profile
        </li>
        <li>
          <code>POST /api/food-logs</code> - Create food log entry
        </li>
        <li>
          <code>GET /api/food-logs</code> - List food logs
        </li>
        <li>
          <code>GET /api/foods/search</code> - Search food database
        </li>
      </ul>
    </div>
  );
}
