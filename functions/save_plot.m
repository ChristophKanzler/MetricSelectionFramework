function save_plot(fig_handle, filename)
    set(fig_handle, 'Units','Inches');
    pos = get(fig_handle, 'Position');
    set(fig_handle, 'PaperPositionMode', 'Auto', 'PaperUnits', 'Inches', 'PaperSize', [pos(3), pos(4)])
    print(fig_handle, fullfile('output_plots', filename), '-dpdf', '-r0')
end

