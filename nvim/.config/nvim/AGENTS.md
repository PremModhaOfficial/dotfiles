# CodeCompanion Agents Instructions

## Current Setup
- **AI Provider**: OpenRouter with free tier models
- **Models**: qwen/qwen3-coder:free (supports tools)
- **Plugins**: Avante.nvim and CodeCompanion for AI assistance
- **Completion**: Blink.cmp integrated with both plugins
- **Tools**: Enabled for enhanced functionality
- **Statusline**: Custom Heirline with dynamic colors and performance optimizations

## Key Insights from Configuration
1. **OpenRouter Integration**: Use `__inherited_from = "openai"` for Avante, `extend("openai")` for CodeCompanion
2. **Free Models**: Stick to models that support tools to avoid 404 errors
3. **Rate Limits**: Free tier has strict limits (wait 10+ seconds between requests)
4. **Blink Integration**: Use autocmds to enable Blink in AI plugin buffers
5. **Tools Support**: Ensure selected model supports function calling/tools
6. **Environment Variables**: Always use `OPENROUTER_API_KEY` for authentication

## Best Practices
- Test configurations with `:CodeCompanion` and `:Avante`
- Check logs with `:CodeCompanion logs` for debugging
- Use Snacks notifications for error visibility
- Keep API keys secure in environment variables
- Update models based on OpenRouter's available free options
- Monitor rate limits and upgrade if needed for heavy usage

## Common Issues & Solutions
- **Rate Limit Errors**: Wait or upgrade OpenRouter plan
- **Tool Support Errors**: Switch to models that support function calling
- **Blink Integration**: Ensure autocmds are in Snacks init for proper loading
- **API Key Issues**: Verify `OPENROUTER_API_KEY` is set correctly
- **Model Changes**: Update both Avante and CodeCompanion configs simultaneously

## Workflow Optimization
- Use CodeCompanion for chat-based AI assistance
- Use Avante for inline code suggestions and edits
- Leverage tools for code execution, file operations, and web search
- Keep conversations focused to minimize back-and-forth
- Use project-specific instructions in avante.md for context

## Model Recommendations
- **Free with Tools**: qwen/qwen3-coder:free
- **Free without Tools**: deepseek/deepseek-r1-0528:free (disable tools)
- **Paid Options**: Consider upgrading for higher limits and better models

## Blink.cmp Update (v1.6.0)
- Updated to latest with ~1.5-3x performance gains and fuzzy matching improvements
- Enabled ghost text and buffer caching (500k limit, recency retention)
- Optimized sources: removed ripgrep from defaults, preserved C-j/C-k mappings
- Integrates with Avante and CodeCompanion for enhanced AI completions

## Configuration Reminders
- Avante: `provider = "openrouter"`, `__inherited_from = "openai"`
- CodeCompanion: `adapters.http.openrouter` with `extend("openai")`
- Blink: Global sources include avante and codecompanion providers
- Notifications: Snacks handles error display
- Logs: Available via `:CodeCompanion logs` for troubleshooting

## User Preferences & Customizations

### Statusline (Heirline)
- **Design**: Clean, minimal with Powerline separators ()
- **Components**: Mode indicator, Git branch, File path, LSP status, Diagnostics, Position
- **Colors**: Dynamic mode-based colors with safe highlight caching
- **Performance**: Optimized with cached highlights and reduced update frequency
- **Layout**: Left components → Space → Right components
- **Features**: Clickable elements, conditional rendering, theme compatibility

### Performance Optimizations
- **Highlight Caching**: Cached `safe_hl()` function results
- **Reduced Updates**: Optimized component refresh frequencies
- **Lazy Loading**: Components load only when needed
- **Memory Management**: Proper cleanup and cache management
- **Update Conditions**: Smart event-based updates only when necessary

### Theme & UI Preferences
- **Colorschemes**: Gruvbox, Tokyo Dark, Cyberdream, and others
- **Minimal Design**: Clean interfaces with essential information
- **Responsive Layout**: Adapts to window size and content
- **Visual Hierarchy**: Clear separation with slants and colors
- **Accessibility**: High contrast elements and readable fonts

### LSP & AI Integration
- **LSP Saga**: Winbar breadcrumbs with file navigation
- **CodeCompanion**: Chat-based AI assistance with tools
- **Avante**: Inline AI suggestions and edits
- **Snacks**: Enhanced notifications and pickers
- **Performance**: Balanced between features and responsiveness

### Development Workflow
- **File Navigation**: LSP-based with Snacks pickers
- **Git Integration**: Gitsigns with branch display
- **Diagnostics**: Inline error/warning indicators
- **Completion**: Blink.cmp with AI provider integration
- **Search**: Telescope/Snacks for efficient file finding

### Key Preferences
- **Performance First**: Optimized for smooth experience
- **Clean Aesthetics**: Minimal but informative design
- **Smart Defaults**: Sensible configurations with customization options
- **Tool Integration**: Seamless AI and development tool integration
- **Maintainability**: Well-documented and organized configuration