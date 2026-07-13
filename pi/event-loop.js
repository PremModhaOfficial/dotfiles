/**
 * Simple Async Event Loop for Pi Agent (JavaScript)
 * Just copy this file - no TypeScript needed!
 */

class EventLoop {
  constructor() {
    this.queue = [];
    this.running = false;
    this.handlers = new Map();
    this.eventListeners = new Map();
    this.results = new Map();
  }

  /**
   * Register a command handler
   */
  registerHandler(name, handler) {
    this.handlers.set(name, handler);
    this.emit("handler:registered", { name });
  }

  /**
   * Listen to events
   */
  on(event, handler) {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event).push(handler);

    // Return unsubscribe function
    return () => {
      const listeners = this.eventListeners.get(event);
      if (listeners) {
        const idx = listeners.indexOf(handler);
        if (idx >= 0) listeners.splice(idx, 1);
      }
    };
  }

  /**
   * Listen once
   */
  once(event, handler) {
    const unsubscribe = this.on(event, async (data) => {
      unsubscribe();
      await handler(data);
    });
    return unsubscribe;
  }

  /**
   * Emit an event
   */
  async emit(event, data) {
    const listeners = this.eventListeners.get(event) || [];
    for (const listener of listeners) {
      try {
        await listener(data);
      } catch (err) {
        console.error(`Error in listener for "${event}":`, err);
      }
    }
  }

  /**
   * Queue a command
   */
  enqueue(name, args = {}) {
    const id = `cmd_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    const cmd = { id, name, args, timestamp: Date.now() };
    this.queue.push(cmd);
    this.emit("command:queued", cmd);
    return id;
  }

  /**
   * Start processing the queue
   */
  async start() {
    if (this.running) return;
    this.running = true;
    this.emit("loop:started");

    while (this.running) {
      if (this.queue.length === 0) {
        // No commands, wait a bit
        await new Promise((resolve) => setTimeout(resolve, 100));
        continue;
      }

      const cmd = this.queue.shift();
      await this.executeCommand(cmd);
    }
  }

  /**
   * Stop the event loop
   */
  async stop() {
    this.running = false;
    this.emit("loop:stopped");
  }

  /**
   * Execute a single command
   */
  async executeCommand(cmd) {
    const startTime = Date.now();
    this.emit("command:started", cmd);

    try {
      const handler = this.handlers.get(cmd.name);
      if (!handler) {
        throw new Error(`No handler registered for command: ${cmd.name}`);
      }

      const result = await handler(cmd);
      const duration = Date.now() - startTime;

      const cmdResult = {
        id: cmd.id,
        status: "success",
        result,
        duration,
      };

      this.results.set(cmd.id, cmdResult);
      this.emit("command:success", cmdResult);
    } catch (error) {
      const duration = Date.now() - startTime;
      const cmdResult = {
        id: cmd.id,
        status: "error",
        error: error instanceof Error ? error : new Error(String(error)),
        duration,
      };

      this.results.set(cmd.id, cmdResult);
      this.emit("command:error", cmdResult);
    }
  }

  /**
   * Get result of a command
   */
  getResult(id) {
    return this.results.get(id);
  }

  /**
   * Wait for a command to complete
   */
  async waitFor(id, timeout = 30000) {
    return new Promise((resolve, reject) => {
      const result = this.results.get(id);
      if (result) {
        resolve(result);
        return;
      }

      let unsubscribeSuccess, unsubscribeError;
      const timer = setTimeout(() => {
        if (unsubscribeSuccess) unsubscribeSuccess();
        if (unsubscribeError) unsubscribeError();
        reject(new Error(`Command ${id} timed out after ${timeout}ms`));
      }, timeout);

      unsubscribeSuccess = this.on("command:success", (res) => {
        if (res.id === id) {
          clearTimeout(timer);
          if (unsubscribeSuccess) unsubscribeSuccess();
          if (unsubscribeError) unsubscribeError();
          resolve(res);
        }
      });

      unsubscribeError = this.on("command:error", (res) => {
        if (res.id === id) {
          clearTimeout(timer);
          if (unsubscribeSuccess) unsubscribeSuccess();
          if (unsubscribeError) unsubscribeError();
          reject(res.error);
        }
      });
    });
  }

  /**
   * Get stats
   */
  getStats() {
    return {
      queueLength: this.queue.length,
      running: this.running,
      totalResults: this.results.size,
      successCount: Array.from(this.results.values()).filter(
        (r) => r.status === "success"
      ).length,
      errorCount: Array.from(this.results.values()).filter(
        (r) => r.status === "error"
      ).length,
    };
  }
}

// Export for node
module.exports = { EventLoop };

// Create and export default instance
const eventLoop = new EventLoop();
module.exports.eventLoop = eventLoop;
