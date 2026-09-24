"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import {
	Sprout,
	Store,
	Truck,
	Building2,
	Lock,
	Mail,
	ArrowRight,
	ShieldCheck,
	AlertCircle,
	Loader2,
} from "lucide-react";
import { loginAction } from "@/app/actions/authActions";

const DEMO_USERS = [
	{
		role: "Farmer",
		email: "farmer@agrilink.lk",
		desc: "Sunil Perera (Produce & Bids)",
		icon: Sprout,
		badgeBg:
			"bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300",
	},
	{
		role: "Wholesale Buyer",
		email: "business@agrilink.lk",
		desc: "Nimal Jayasuriya (Keells Procurement)",
		icon: Store,
		badgeBg: "bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300",
	},
	{
		role: "Logistics Carrier",
		email: "transporter@agrilink.lk",
		desc: "Ruwan Fernando (Fleet & Freight)",
		icon: Truck,
		badgeBg:
			"bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300",
	},
	{
		role: "Government Admin",
		email: "gov@agrilink.lk",
		desc: "Agri Officer (Observatory & KYC)",
		icon: Building2,
		badgeBg:
			"bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300",
	},
];

export default function LoginPage() {
	const router = useRouter();
	const [email, setEmail] = useState("gov@agrilink.lk");
	const [password, setPassword] = useState("password123");
	const [error, setError] = useState<string | null>(null);
	const [loading, setLoading] = useState(false);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();
		setError(null);
		setLoading(true);

		try {
			const res = await loginAction({ email, password });
			if (res.success) {
				router.push("/");
				router.refresh();
			} else {
				setError(
					res.error || "Authentication failed. Please verify credentials.",
				);
			}
		} catch (err: any) {
			setError(err?.message || "Network error occurred. Please try again.");
		} finally {
			setLoading(false);
		}
	};

	const fillDemo = (demoEmail: string) => {
		setEmail(demoEmail);
		setPassword("password123");
		setError(null);
	};

	return (
		<div className="flex min-h-screen bg-zinc-50 font-sans antialiased dark:bg-zinc-950">
			{/* Left visual banner (Sri Lankan agriculture) */}
			<div className="relative hidden w-1/2 flex-col justify-between overflow-hidden bg-gradient-to-br from-emerald-900 via-emerald-950 to-zinc-950 p-12 text-white lg:flex">
				<div className="relative z-10">
					<div className="inline-flex items-center gap-2 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-3.5 py-1 text-xs font-semibold tracking-wide text-emerald-300 backdrop-blur-md">
						<span>🇱🇰 SRI LANKAN AGRICULTURAL EXCHANGE</span>
					</div>
					<div className="mt-8 flex items-center gap-3">
						<div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-500 text-zinc-950 shadow-lg shadow-emerald-500/20">
							<Sprout className="h-7 w-7" />
						</div>
						<div>
							<h1 className="text-3xl font-extrabold tracking-tight">
								AgriLink
							</h1>
							<p className="text-sm font-medium text-emerald-300">
								National BitApp Operations Center
							</p>
						</div>
					</div>
				</div>

				<div className="relative z-10 max-w-lg space-y-6">
					<blockquote className="space-y-2 border-l-2 border-emerald-400 pl-4 text-lg font-light text-zinc-200">
						<p>
							&ldquo;Connecting smallholder farmers directly to wholesale
							buyers, verified logistics carriers, and government market
							intelligence.&rdquo;
						</p>
					</blockquote>
					<div className="grid grid-cols-2 gap-4 pt-4 text-xs">
						<div className="rounded-xl border border-emerald-500/20 bg-emerald-950/40 p-4 backdrop-blur-xs">
							<p className="font-semibold text-emerald-400">
								Direct Farmgate Pricing
							</p>
							<p className="mt-1 text-zinc-400">
								Eliminating intermediaries to deliver up to 35% higher net farm
								profit.
							</p>
						</div>
						<div className="rounded-xl border border-emerald-500/20 bg-emerald-950/40 p-4 backdrop-blur-xs">
							<p className="font-semibold text-emerald-400">
								Live Freight & Waybills
							</p>
							<p className="mt-1 text-zinc-400">
								Integrated transport tracking with secure OTP sign-off.
							</p>
						</div>
					</div>
				</div>

				{/* Decorative background glow */}
				<div className="absolute -top-32 -left-32 h-96 w-96 rounded-full bg-emerald-600/20 blur-3xl" />
				<div className="absolute -bottom-32 -right-32 h-96 w-96 rounded-full bg-emerald-500/10 blur-3xl" />
			</div>

			{/* Right form side */}
			<div className="flex flex-1 flex-col justify-center px-6 py-12 sm:px-12 lg:px-16">
				<div className="mx-auto w-full max-w-md">
					{/* Mobile brand header */}
					<div className="mb-8 flex items-center gap-3 lg:hidden">
						<div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-600 text-white shadow-sm">
							<Sprout className="h-6 w-6" />
						</div>
						<div>
							<h2 className="text-xl font-bold text-zinc-900 dark:text-zinc-100">
								AgriLink Dashboard
							</h2>
							<p className="text-xs text-zinc-500">Sign in to your account</p>
						</div>
					</div>

					<div className="mb-8 hidden lg:block">
						<h2 className="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-100">
							Welcome Back
						</h2>
						<p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
							Sign in with your email and password to access your role
							dashboard.
						</p>
					</div>

					{error && (
						<div className="mb-6 flex items-start gap-3 rounded-xl border border-red-200 bg-red-50 p-4 text-xs text-red-800 dark:border-red-900/50 dark:bg-red-950/40 dark:text-red-300">
							<AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-600 dark:text-red-400" />
							<div className="flex-1 font-medium">{error}</div>
						</div>
					)}

					<form onSubmit={handleSubmit} className="space-y-4">
						<div>
							<label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300">
								Email Address
							</label>
							<div className="relative mt-1.5">
								<Mail className="absolute top-1/2 left-3.5 h-4 w-4 -translate-y-1/2 text-zinc-400" />
								<input
									type="email"
									required
									value={email}
									onChange={(e) => setEmail(e.target.value)}
									placeholder="name@agrilink.lk"
									className="w-full rounded-xl border border-zinc-200 bg-white py-2.5 pr-4 pl-10 text-sm text-zinc-900 placeholder-zinc-400 shadow-2xs transition-colors focus:border-emerald-600 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-100 dark:placeholder-zinc-500"
								/>
							</div>
						</div>

						<div>
							<div className="flex items-center justify-between">
								<label className="block text-xs font-semibold text-zinc-700 dark:text-zinc-300">
									Password
								</label>
							</div>
							<div className="relative mt-1.5">
								<Lock className="absolute top-1/2 left-3.5 h-4 w-4 -translate-y-1/2 text-zinc-400" />
								<input
									type="password"
									required
									value={password}
									onChange={(e) => setPassword(e.target.value)}
									placeholder="••••••••••••"
									className="w-full rounded-xl border border-zinc-200 bg-white py-2.5 pr-4 pl-10 text-sm text-zinc-900 placeholder-zinc-400 shadow-2xs transition-colors focus:border-emerald-600 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/20 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-100 dark:placeholder-zinc-500"
								/>
							</div>
						</div>

						<button
							type="submit"
							disabled={loading}
							className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl bg-emerald-700 py-3 text-sm font-semibold text-white shadow-md shadow-emerald-700/20 transition-all hover:bg-emerald-800 focus:ring-2 focus:ring-emerald-600 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-70 dark:bg-emerald-600 dark:hover:bg-emerald-500"
						>
							{loading ? (
								<>
									<Loader2 className="h-4 w-4 animate-spin" />
									<span>Signing in...</span>
								</>
							) : (
								<>
									<span>Sign In to Dashboard</span>
									<ArrowRight className="h-4 w-4" />
								</>
							)}
						</button>
					</form>

					{/* Quick Demo Logins Section */}
					<div className="mt-8 border-t border-zinc-200 pt-6 dark:border-zinc-800">
						<p className="text-center text-[11px] font-semibold uppercase tracking-wider text-zinc-400">
							Quick Test Login (Demo Accounts)
						</p>
						<p className="mt-1 text-center text-xs text-zinc-500 dark:text-zinc-400">
							Click any account below to autofill credentials:
						</p>

						<div className="mt-4 grid grid-cols-1 gap-2.5 sm:grid-cols-2">
							{DEMO_USERS.map((user) => {
								const Icon = user.icon;
								const isSelected = email === user.email;
								return (
									<button
										key={user.email}
										type="button"
										onClick={() => fillDemo(user.email)}
										className={`flex items-start gap-2.5 rounded-xl border p-2.5 text-left transition-all ${
											isSelected
												? "border-emerald-500 bg-emerald-50/70 ring-1 ring-emerald-500/50 dark:border-emerald-500 dark:bg-emerald-950/40"
												: "border-zinc-200 bg-white hover:border-zinc-300 hover:bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700 dark:hover:bg-zinc-800/60"
										}`}
									>
										<div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-zinc-100 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300">
											<Icon className="h-4 w-4" />
										</div>
										<div className="min-w-0 flex-1">
											<span
												className={`inline-block rounded px-1.5 py-0.5 text-[10px] font-semibold ${user.badgeBg}`}
											>
												{user.role}
											</span>
											<p className="mt-1 truncate text-xs font-semibold text-zinc-900 dark:text-zinc-100">
												{user.email}
											</p>
											<p className="truncate text-[10px] text-zinc-500 dark:text-zinc-400">
												{user.desc}
											</p>
										</div>
									</button>
								);
							})}
						</div>
					</div>
				</div>
			</div>
		</div>
	);
}
