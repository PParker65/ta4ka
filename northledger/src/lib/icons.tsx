import {
  ClipboardList,
  FileOutput,
  FileText,
  KeyRound,
  Landmark,
  LayoutDashboard,
  Lock,
  Receipt,
  ScrollText,
  Users,
  type LucideIcon,
} from "lucide-react";
import type { FeatureIconName, SecurityIconName } from "./types";

export const featureIconMap: Record<FeatureIconName, LucideIcon> = {
  "file-text": FileText,
  receipt: Receipt,
  "scroll-text": ScrollText,
  landmark: Landmark,
  users: Users,
  "layout-dashboard": LayoutDashboard,
};

export const securityIconMap: Record<SecurityIconName, LucideIcon> = {
  lock: Lock,
  "key-round": KeyRound,
  users: Users,
  "clipboard-list": ClipboardList,
  "file-output": FileOutput,
};

export const featureIconLabels: Record<FeatureIconName, string> = {
  "file-text": "Invoice",
  receipt: "Receipt",
  "scroll-text": "Report",
  landmark: "Bank",
  users: "Team",
  "layout-dashboard": "Portal",
};

export const securityIconLabels: Record<SecurityIconName, string> = {
  lock: "Lock",
  "key-round": "Key",
  users: "Roles",
  "clipboard-list": "Audit log",
  "file-output": "Export",
};
