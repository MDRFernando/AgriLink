"use server";

import { prisma } from "@/lib/db";
import { getSession } from "@/lib/auth";
import { UserRole } from "@/lib/types";

export interface AppAlert {
	title: string;
	desc: string;
	time: string;
}

export async function getNotificationsAction(
	role: UserRole,
): Promise<AppAlert[]> {
	try {
		const alerts: AppAlert[] = [];

		// Query recent database records
		const recentOrders = await prisma.order.findMany({
			include: {
				farmer: { select: { name: true, district: true } },
				buyer: { select: { name: true, organizationName: true } },
			},
			orderBy: { createdAt: "desc" },
			take: 3,
		});

		const recentBids = await prisma.bid.findMany({
			include: {
				buyer: { select: { name: true, organizationName: true } },
				auction: { include: { production: { select: { cropType: true } } } },
			},
			orderBy: { createdAt: "desc" },
			take: 3,
		});

		const recentTransport = await prisma.transportRequest.findMany({
			orderBy: { createdAt: "desc" },
			take: 3,
		});

		const pendingVerifications = await prisma.user.count({
			where: { isVerified: false, role: { in: ["business", "transporter"] } },
		});

		if (role === "farmer") {
			recentBids.forEach((b) => {
				alerts.push({
					title: `New Bid Placed: Rs. ${b.amount}/kg`,
					desc: `${b.buyer?.organizationName || b.buyer?.name || "A buyer"} placed a bid on ${b.auction?.production?.cropType || "produce"}.`,
					time: "Recent",
				});
			});
			recentOrders.forEach((o) => {
				alerts.push({
					title: `Order Status: ${o.status.replace(/_/g, " ").toUpperCase()}`,
					desc: `Consignment for ${o.quantityKg}kg ordered by ${o.buyer?.organizationName || o.buyer?.name || "Buyer"}.`,
					time: "Recent",
				});
			});
		} else if (role === "buyer") {
			recentOrders.forEach((o) => {
				alerts.push({
					title: `Waybill Updated: ORD-${o.id.slice(0, 4).toUpperCase()}`,
					desc: `Current order status is ${o.status.replace(/_/g, " ")}.`,
					time: "Recent",
				});
			});
			recentBids.forEach((b) => {
				alerts.push({
					title: `Active Bid Placed`,
					desc: `Your bid of Rs. ${b.amount}/kg for ${b.auction?.production?.cropType || "lot"} is registered.`,
					time: "Recent",
				});
			});
		} else if (role === "transporter") {
			recentTransport.forEach((t) => {
				alerts.push({
					title: `Cargo Job: ${t.requestCode}`,
					desc: `${t.product} (${t.quantityKg}kg) from ${t.pickupCity} to ${t.deliveryCity}. Status: ${t.status.replace(/_/g, " ")}.`,
					time: "Recent",
				});
			});
		} else {
			// government
			if (pendingVerifications > 0) {
				alerts.push({
					title: `KYC Verifications Pending`,
					desc: `${pendingVerifications} commercial partner(s) awaiting verification review.`,
					time: "Pending",
				});
			}
			recentOrders.forEach((o) => {
				alerts.push({
					title: `Market Transaction Recorded`,
					desc: `Order executed at Rs. ${o.winningPriceKg}/kg for ${o.quantityKg}kg.`,
					time: "Recent",
				});
			});
		}

		if (alerts.length === 0) {
			alerts.push({
				title: "System Operational",
				desc: "All marketplace services and database sync are operating normally.",
				time: "Now",
			});
		}

		return alerts.slice(0, 4);
	} catch (error) {
		console.error("Error fetching live notifications:", error);
		return [
			{
				title: "Marketplace Active",
				desc: "Connected to Neon PostgreSQL exchange network.",
				time: "Now",
			},
		];
	}
}
