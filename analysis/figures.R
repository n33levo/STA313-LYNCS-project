ink <- "#252525"
blue <- "#2166ac"
grey <- "#777777"
paper <- "#faf9f6"
colours <- c(OW = grey, ODSP = blue)
theme_set(theme_minimal(base_size = 12, base_family = "sans") +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "#dedbd5", linewidth = 0.3),
        plot.title = element_text(family = "serif", size = 21, colour = ink),
        plot.subtitle = element_text(colour = grey, margin = margin(b = 16)),
        plot.caption = element_text(hjust = 0, colour = grey, margin = margin(t = 15)),
        axis.title = element_text(size = 11), axis.text = element_text(colour = ink),
        legend.position = "top", legend.title = element_blank(),
        plot.margin = margin(18, 24, 18, 18), strip.text = element_text(face = "bold")))
save_fig <- function(p, name, w = 10, h = 6) {
  ggsave(file.path("analysis/figures", paste0(name, ".png")), p, width = w, height = h,
         dpi = 220, bg = paper)
}

# A record-to-location comparison, rather than sixteen campus symbols.
x <- aggregate(id ~ city, latest, length)
names(x)[2] <- "records"
y <- aggregate(location ~ city, unique(latest[c("city", "location")]), length)
x <- merge(x, y, by = "city")
x$label <- c(Belleville = "Belleville\nOutside coverage", Brantford = "Brantford CMA",
              London = "London CMA", Milton = "Milton\nToronto CMA")[x$city]
x$label <- factor(x$label, levels = rev(x$label))
p <- ggplot(x, aes(y = label)) +
  geom_segment(aes(x = location, xend = records, yend = label), colour = "#bababa", linewidth = 1) +
  geom_point(aes(x = records, colour = "School records", shape = "School records"), size = 4) +
  geom_point(aes(x = location, colour = "Reported locations", shape = "Reported locations"), size = 4) +
  scale_colour_manual(name = NULL, breaks = c("School records", "Reported locations"),
                      values = c("School records" = blue, "Reported locations" = ink)) +
  scale_shape_manual(name = NULL, breaks = c("School records", "Reported locations"),
                     values = c("School records" = 16, "Reported locations" = 1)) +
  scale_x_continuous(breaks = 0:5, limits = c(0, 5)) +
  labs(title = "Sixteen records, five reported locations", subtitle = "Selected school codes, 2024-2025",
       x = "Count", y = NULL,
       caption = "Shared coordinates are counted once. Locations are not verified campus boundaries.\nSource: course school file; 2021 CMA reference geography.")
save_fig(p, "01-school-locations", h = 4.8)

# Two aligned count scales; the school selection does not remove other areas.
order <- now$name[now$programme == "ODSP"][order(now$cases[now$programme == "ODSP"])]
x <- now
x$name <- factor(x$name, levels = order)
p <- ggplot(x, aes(cases / 1000, name, colour = programme)) +
  geom_segment(aes(x = 0, xend = cases / 1000, yend = name), linewidth = 0.6) +
  geom_point(size = 2.6) +
  geom_text(aes(label = format(cases, big.mark = ",", trim = TRUE)), hjust = -0.25, size = 3) +
  facet_grid(. ~ programme) + scale_colour_manual(values = colours) +
  scale_x_continuous(limits = c(0, max(x$cases) / 1000 * 1.2), breaks = c(0, 50, 100)) +
  labs(title = "Compare caseloads on the same scale", subtitle = "All 15 covered areas, March 2025",
       x = "Cases (thousands)", y = NULL,
       caption = "A case is one person or a family unit. Totals are not adjusted for area population.\nSource: course OW and ODSP CMA files.") + theme(legend.position = "none")
save_fig(p, "02-area-comparison", h = 7)

x <- a
x$index <- ave(x$cases, interaction(x$programme, x$area), FUN = function(v) 100 * v / v[1])
x$name <- factor(x$name, levels = sort(unique(x$name)))
p <- ggplot(x, aes(date, index, colour = programme, linetype = programme)) +
  geom_hline(yintercept = 100, colour = "#bdbdbd", linewidth = 0.35) +
  geom_vline(xintercept = as.Date("2025-03-31"), colour = "#bdbdbd", linetype = "dotted") +
  geom_line(linewidth = 0.55) + facet_wrap(~ name, ncol = 3) +
  scale_colour_manual(values = colours) + scale_linetype_manual(values = c(OW = "dashed", ODSP = "solid")) +
  scale_x_date(breaks = as.Date(paste0(c(2003, 2014, 2026), "-03-31")), date_labels = "%Y") +
  labs(title = "A different history in each area", subtitle = "March 2003 = 100; shared scale across all panels",
       x = NULL, y = "Caseload index",
       caption = "Dotted line: March 2025, paired with the latest school year. Index lines compare change, not caseload size.\nSource: course OW and ODSP CMA files. Historical boundary equivalence is unconfirmed.") +
  theme(panel.grid.major.x = element_blank(), panel.grid.major.y = element_line(colour = "#e5e2dc", linewidth = .25))
save_fig(p, "03-caseload-histories", h = 10)

x <- do.call(rbind, lapply(c("fts", "ftsp", "ftc"), function(v)
  data.frame(name = now$name, programme = now$programme, type = v, pct = 100 * now[[v]] / now$cases)))
x$name <- factor(x$name, levels = order)
x$type <- factor(x$type, levels = c("fts", "ftsp", "ftc"),
                  labels = c("Single, without children", "Single parent", "Couple, with or without children"))
p <- ggplot(x, aes(pct, name, colour = programme, shape = programme)) +
  geom_point(size = 2.7, position = position_dodge(width = 0.45)) + facet_grid(. ~ type) +
  scale_colour_manual(values = colours) + scale_shape_manual(values = c(OW = 1, ODSP = 16)) +
  scale_x_continuous(limits = c(0, 100), breaks = c(0, 50, 100)) +
  labs(title = "Who makes up the caseload?", subtitle = "Family type, March 2025",
       x = "Percentage of cases within each area and programme", y = NULL,
       caption = "Each programme's three family categories sum to 100%. These are family units, not individual recipients.\nSource: course OW and ODSP CMA files.")
save_fig(p, "04-family-composition", w = 12, h = 7)
