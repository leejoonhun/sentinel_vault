//! # Sentinel Vault - Solana Program
//!
//! Automated DeFi risk management protocol for Solana.
//! This program provides:
//! - Stop-loss order execution
//! - Take-profit order management
//! - Flash loan integration (via Solana lending protocols)
//!
//! ## Architecture
//! Unlike EVM where contract storage is internal, Solana separates:
//! - **Program**: Stateless logic (this file)
//! - **Accounts**: User-owned data (orders, vaults, etc.)

use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

/// Main program module for Sentinel Vault
#[program]
pub mod sentinel_vault {
    use super::*;

    /// Initialize a new vault for a user
    pub fn initialize_vault(ctx: Context<InitializeVault>) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.owner = ctx.accounts.owner.key();
        vault.bump = ctx.bumps.vault;
        vault.order_count = 0;
        vault.created_at = Clock::get()?.unix_timestamp;

        msg!("Vault initialized for owner: {}", vault.owner);
        Ok(())
    }

    /// Create a new stop-loss order
    pub fn create_order(
        ctx: Context<CreateOrder>,
        order_type: OrderType,
        trigger_price: u64,
        amount: u64,
        token_mint: Pubkey,
    ) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        let order = &mut ctx.accounts.order;

        order.vault = vault.key();
        order.owner = ctx.accounts.owner.key();
        order.order_id = vault.order_count;
        order.order_type = order_type;
        order.trigger_price = trigger_price;
        order.amount = amount;
        order.token_mint = token_mint;
        order.status = OrderStatus::Active;
        order.created_at = Clock::get()?.unix_timestamp;
        order.bump = ctx.bumps.order;

        vault.order_count = vault.order_count.checked_add(1).unwrap();

        msg!(
            "Order {} created: {:?} at price {}",
            order.order_id,
            order.order_type,
            trigger_price
        );
        Ok(())
    }

    /// Execute an order (called by keeper)
    pub fn execute_order(ctx: Context<ExecuteOrder>) -> Result<()> {
        let order = &mut ctx.accounts.order;

        require!(
            order.status == OrderStatus::Active,
            SentinelError::OrderNotActive
        );

        // TODO: Implement actual swap logic via Jupiter/Raydium CPI
        // For now, just mark as executed
        order.status = OrderStatus::Executed;
        order.executed_at = Some(Clock::get()?.unix_timestamp);

        msg!("Order {} executed", order.order_id);
        Ok(())
    }

    /// Cancel an order (owner only)
    pub fn cancel_order(ctx: Context<CancelOrder>) -> Result<()> {
        let order = &mut ctx.accounts.order;

        require!(
            order.status == OrderStatus::Active,
            SentinelError::OrderNotActive
        );

        order.status = OrderStatus::Cancelled;

        msg!("Order {} cancelled", order.order_id);
        Ok(())
    }
}

// ============================================================================
// Account Structures
// ============================================================================

/// User's vault account - stores metadata about their orders
#[account]
#[derive(InitSpace)]
pub struct Vault {
    /// Owner of this vault
    pub owner: Pubkey,
    /// PDA bump seed
    pub bump: u8,
    /// Total orders created (used as order ID counter)
    pub order_count: u64,
    /// Unix timestamp of vault creation
    pub created_at: i64,
}

/// Individual order account
#[account]
#[derive(InitSpace)]
pub struct Order {
    /// Parent vault
    pub vault: Pubkey,
    /// Order owner
    pub owner: Pubkey,
    /// Unique order ID within the vault
    pub order_id: u64,
    /// Type of order (StopLoss, TakeProfit, etc.)
    pub order_type: OrderType,
    /// Price at which to trigger execution
    pub trigger_price: u64,
    /// Amount of tokens to swap
    pub amount: u64,
    /// Token mint address
    pub token_mint: Pubkey,
    /// Current status
    pub status: OrderStatus,
    /// Creation timestamp
    pub created_at: i64,
    /// Execution timestamp (if executed)
    pub executed_at: Option<i64>,
    /// PDA bump seed
    pub bump: u8,
}

// ============================================================================
// Enums
// ============================================================================

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, Debug, PartialEq, Eq, InitSpace)]
pub enum OrderType {
    StopLoss,
    TakeProfit,
    TrailingStop,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, Debug, PartialEq, Eq, InitSpace)]
pub enum OrderStatus {
    Active,
    Executed,
    Cancelled,
    Expired,
}

// ============================================================================
// Contexts (Account Validation)
// ============================================================================

#[derive(Accounts)]
pub struct InitializeVault<'info> {
    #[account(
        init,
        payer = owner,
        space = 8 + Vault::INIT_SPACE,
        seeds = [b"vault", owner.key().as_ref()],
        bump
    )]
    pub vault: Account<'info, Vault>,

    #[account(mut)]
    pub owner: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CreateOrder<'info> {
    #[account(
        mut,
        seeds = [b"vault", owner.key().as_ref()],
        bump = vault.bump,
        has_one = owner
    )]
    pub vault: Account<'info, Vault>,

    #[account(
        init,
        payer = owner,
        space = 8 + Order::INIT_SPACE,
        seeds = [b"order", vault.key().as_ref(), &vault.order_count.to_le_bytes()],
        bump
    )]
    pub order: Account<'info, Order>,

    #[account(mut)]
    pub owner: Signer<'info>,

    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct ExecuteOrder<'info> {
    #[account(
        mut,
        seeds = [b"order", order.vault.as_ref(), &order.order_id.to_le_bytes()],
        bump = order.bump
    )]
    pub order: Account<'info, Order>,

    /// Keeper/executor - anyone can execute if conditions are met
    pub executor: Signer<'info>,
}

#[derive(Accounts)]
pub struct CancelOrder<'info> {
    #[account(
        mut,
        seeds = [b"order", order.vault.as_ref(), &order.order_id.to_le_bytes()],
        bump = order.bump,
        has_one = owner
    )]
    pub order: Account<'info, Order>,

    pub owner: Signer<'info>,
}

// ============================================================================
// Errors
// ============================================================================

#[error_code]
pub enum SentinelError {
    #[msg("Order is not in active status")]
    OrderNotActive,
    #[msg("Trigger condition not met")]
    TriggerNotMet,
    #[msg("Unauthorized access")]
    Unauthorized,
    #[msg("Invalid price")]
    InvalidPrice,
    #[msg("Arithmetic overflow")]
    Overflow,
}
