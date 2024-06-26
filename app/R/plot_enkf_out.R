#' Plot EnKF output
#' @param obs_plot list of historical and future dataframes of observations
#' @param start_date forecast date in "YYYY-mm-dd" format
#' @param plot_type either 'Line' or 'Distribution'
#' @param est_out output from `EnKF()` formatted with `format_enkf_output()`
#' @param var Can be 'chla', 'nitrate' or 'maxUptake'
#' @param add_obs Add future observations. Defaults to FALSE

plot_enkf_out <- function(obs_plot, start_date, plot_type, est_out, var, add_obs = FALSE, n_days, h_line = NULL, show_assim = TRUE) {
  
  dat2 <- obs_plot$hist
  if(var == "chla") {
    dat2$col <- "Chlorophyll-a"
    y_lab <- "Chlorophyll-a (μg/L)"
  } else if(var == "nitrate") {
    dat2$col <- "Nitrate"
    y_lab <- "Nitrate (μm L-1)"
  } else if(var == "maxUptake") {
    dat2$col <- "Max uptake"
    y_lab <- "Max Uptake (-)"
  }
  
  
  p <- ggplot() +
    # geom_point(data = dat2, aes_string("Date", var, color = "col")) +
    # geom_vline(xintercept = as.Date(start_date), linetype = "dashed") +
    ylab(y_lab) +
    xlab("Date") +
    theme_bw(base_size = 12)
  
  df <- est_out[[var]]$ens
  df$value[df$Date > (as.Date(start_date) + n_days)] <- NA
  
  df2 <- est_out[[var]]$dist
  df2[df2$Date > (as.Date(start_date) + n_days), -ncol(df2)] <- NA
  
  if(plot_type == "Line") {
    p <- p +
      geom_line(data = df, aes(Date, value, group = variable, color = "Member"), color = "gray", alpha = 0.6)
  } else if (plot_type == "Distribution") {
    p <- p +
      geom_ribbon(data = df2, aes(Date, ymin = p5, ymax = p95, fill = "95%"), alpha = 0.6) +
      geom_ribbon(data = df2, aes(Date, ymin = p12.5, ymax = p87.5, fill = "75%"), alpha = 0.3) +
      geom_line(data = df2, aes(Date, p50, color = "median"))
  }
  
  if(add_obs) {
    dat3 <- obs_plot$future
    if(var == "chla") {
      dat3$col <- "Chlorophyll-a"
    } 
    if(var == "nitrate") {
      dat3$col <- "Nitrate"
    } 
    if(var == "maxUptake") {
      dat3$col <- "Max uptake"
    }
    p <- p +
      geom_point(data = dat3, aes_string("Date", var, color = "col"))
  }
  
  if(var != "maxUptake" & show_assim) {
    dat3 <- est_out[[var]]$obs
    dat3$obs[dat3$Date > (as.Date(start_date) + (n_days))] <- NA
    dat3$col <- "Assimilated"
    p <- p +
      geom_errorbar(data = dat3, aes(Date, ymin = obs - est_out[[var]]$state_sd, ymax = obs + est_out[[var]]$state_sd,
                                     width = 1)) +
      geom_point(data = dat3, aes_string("Date", "obs", color = "col"))
  }
  
  p <- p +
    scale_color_manual(values = c("Chlorophyll-a" = cols[1], "Nitrate" = cols[7], "Max uptake" = cols[4],
                                  "Member" = l.cols[8], "median" = "black", "95%" = p.cols[5], "75%" = p.cols[6], "Obs" = p.cols[4],
                                  "Assimilated" = cols[4])) +
    scale_fill_manual(values = c("95%" = p.cols[3], "75%" = p.cols[4]))
  
  if(!is.null(h_line)) {
    p <- p + 
      geom_hline(yintercept = h_line, linetype = "dashed")
  }
  
  gp <- ggplotly(p, dynamicTicks = TRUE)
  for (i in 1:length(gp$x$data)){
    if (!is.null(gp$x$data[[i]]$name)){
      gp$x$data[[i]]$name =  gsub("\\(","", stringr::str_split(gp$x$data[[i]]$name,",")[[1]][1])
    }
  }
  return(gp)
}