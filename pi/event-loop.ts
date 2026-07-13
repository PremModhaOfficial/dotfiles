/**
 * Simple Async Event Loop for Pi Agent
 * Queues and executes commands asynchronously with event hooks
 */

export type EventHandler<T = any> = (data: T) => void | Promise<void>;
export type CommandHandler = (cmd: Command) => Promise<any>;

export interface Command {
  id: string;
  name: string;
  args: Record<string, any>;
  timestamp: number;
}

export interface CommandResult {
  id: string;
  status: "success" | "error" | "pending";
  result?: any;
  error?: Error;
  duration: number;
}

/**
 * Simple, extensible event loop
 */
export class EventLoop {
  private queue: Command[] = [];
  private running = false;
  private handlers: Map<string, CommandHandler> = new Map();
  private eventListeners: Map<string, EventHandler[]> = new Map();
  private results: Map<string, CommandResult> = new Map();

  /**
   * Register a command handler
   */
  registerHandler(name: string, handler: CommandHandler): void {
    this.handlers.set(name, handler);
    this.emit("handler:registered", { name });
  }

  /**
   * Listen to events
   */
  on(event: string, handler: EventHandler): () => void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(handler);
    
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
  once(event: string, handler: EventHandler): () => void {
    const unsubscribe = this.on(event, async (data) => {
      unsubscribe();
      await handler(data);
    });
    return unsubscribe;
  }

  /**
   * Emit an event
   */
  private async emit(event: string, data?: any): Promise<void> {
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
  enqueue(name: string, args: Record<string, any> = {}): string {
    const id = `cmd_${Date.now()}_${Math.random().toString(36).slice(2)}`;
    const cmd: Command = { id, name, args, timestamp: Date.now() };
    this.queue.push(cmd);
    this.emit("command:queued", cmd);
    return id;
  }

  /**
   * Start processing the queue
   */
  async start(): Promise<void> {
    if (this.running) return;
    this.running = true;
    this.emit("loop:started");

    while (this.running) {
      if (this.queue.length === 0) {
        // No commands, wait a bit
        await new Promise((resolve) => setTimeout(resolve, 100));
        continue;
      }

      const cmd = this.queue.shift()!;
      await this.executeCommand(cmd);
    }
  }

  /**
   * Stop the event loop
   */
  async stop(): Promise<void> {
    this.running = false;
    this.emit("loop:stopped");
  }

  /**
   * Execute a single command
   */
  private async executeCommand(cmd: Command): Promise<void> {
    const startTime = Date.now();
    this.emit("command:started", cmd);

    try {
      const handler = this.handlers.get(cmd.name);
      if (!handler) {
        throw new Error(`No handler registered for command: ${cmd.name}`);
      }

      const result = await handler(cmd);
      const duration = Date.now() - startTime;

      const cmdResult: CommandResult = {
        id: cmd.id,
        status: "success",
        result,
        duration,
      };

      this.results.set(cmd.id, cmdResult);
      this.emit("command:success", cmdResult);
    } catch (error) {
      const duration = Date.now() - startTime;
      const cmdResult: CommandResult = {
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
  getResult(id: string): CommandResult | undefined {
    return this.results.get(id);
  }

  /**
   * Wait for a command to complete
   */
  async waitFor(id: string, timeout = 30000): Promise<CommandResult> {
    return new Promise((resolve, reject) => {
      const result = this.results.get(id);
      if (result) {
        resolve(result);
        return;
      }

      const timer = setTimeout(() => {
        unsubscribe();
        reject(new Error(`Command ${id} timed out after ${timeout}ms`));
      }, timeout);

      const unsubscribe = this.on("command:success", (res) => {
        if (res.id === id) {
          clearTimeout(timer);
          unsubscribe();
          resolve(res);
        }
      });

      this.on("command:error", (res) => {
        if (res.id === id) {
          clearTimeout(timer);
          unsubscribe();
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

/**
 * Create and export default instance
 */
export const eventLoop = new EventLoop();
