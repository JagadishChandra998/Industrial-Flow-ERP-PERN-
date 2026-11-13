import Express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { pool } from "./config/db.ts";

dotenv.config();

const app = Express();
app.use(cors());
app.use(Express.json());

app.get("/", (req, res) => {
    res.json({
        message: "IndustrialFlow ERP API is running"
    });
});

app.get("/api/health", async (_req, res) => {
    try {
        await pool.query("SELECT NOW()");
        res.json({
            success: true,
            message: "Database connected successfully"
        });
    }
    catch (error) {
        console.error("DATABASE ERROR:", error);

        res.status(500).json({
            success: false,
            message: "Database connection failed"
        });
    }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`🚀 Server running at http://localhost:${PORT}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/api/health`);
});