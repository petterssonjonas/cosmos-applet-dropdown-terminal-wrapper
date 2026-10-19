use std::path::PathBuf;

use cosmic::prelude::*;

#[derive(Default)]
struct Applet {
    core: cosmic::Core,
    pending: bool,
    error: Option<String>,
}

#[derive(Clone)]
enum Message {
    Toggle,
    Finished(Result<(), String>),
    SurfaceAction(cosmic::surface::Action<Message>),
}

impl std::fmt::Debug for Message {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(match self {
            Self::Toggle => "Toggle",
            Self::Finished(_) => "Finished",
            Self::SurfaceAction(_) => "SurfaceAction",
        })
    }
}

impl cosmic::Application for Applet {
    type Executor = cosmic::executor::Default;
    type Flags = ();
    type Message = Message;
    const APP_ID: &'static str = "dev.jp.CosmosAppletDropdownTerminalWrapper";

    fn core(&self) -> &cosmic::Core {
        &self.core
    }

    fn core_mut(&mut self) -> &mut cosmic::Core {
        &mut self.core
    }

    fn init(core: cosmic::Core, _: ()) -> (Self, Task<cosmic::Action<Message>>) {
        (
            Self {
                core,
                ..Self::default()
            },
            Task::none(),
        )
    }

    fn view(&self) -> Element<'_, Message> {
        let button = self
            .core
            .applet
            .icon_button("utilities-terminal-symbolic")
            .on_press_maybe((!self.pending).then_some(Message::Toggle));
        self.core
            .applet
            .applet_tooltip(
                button,
                self.error
                    .clone()
                    .unwrap_or_else(|| "Cosmos Dropdown Terminal (Kitty) · Super+§".to_owned()),
                false,
                Message::SurfaceAction,
                self.core.main_window_id(),
            )
            .into()
    }

    fn update(&mut self, message: Message) -> Task<cosmic::Action<Message>> {
        match message {
            Message::SurfaceAction(action) => return cosmic::surface::surface_task(action),
            Message::Toggle if !self.pending => {
                self.pending = true;
                self.error = None;
                return Task::perform(toggle(), |result| {
                    cosmic::Action::App(Message::Finished(result))
                });
            }
            Message::Finished(result) => {
                self.pending = false;
                if let Err(error) = result {
                    eprintln!("Dropdown terminal: {error}");
                    self.error = Some(error);
                }
            }
            Message::Toggle => {}
        }
        Task::none()
    }

    fn style(&self) -> Option<cosmic::iced::theme::Style> {
        Some(cosmic::applet::style())
    }
}

async fn toggle() -> Result<(), String> {
    let command = std::env::var_os("COSMOS_DROPDOWN_WRAPPER")
        .map(PathBuf::from)
        .or_else(|| {
            std::env::current_exe()
                .ok()
                .map(|path| path.with_file_name("cosmos-applet-dropdown-terminal-wrapper-toggle"))
        })
        .unwrap_or_else(|| PathBuf::from("cosmos-applet-dropdown-terminal-wrapper-toggle"));
    let mut process = tokio::process::Command::new(command);
    process.env_remove("WAYLAND_SOCKET").kill_on_drop(true);
    let output = tokio::time::timeout(std::time::Duration::from_secs(15), process.output())
        .await
        .map_err(|_| "Wrapper did not respond within 15 seconds".to_owned())?
        .map_err(|error| format!("Could not start the wrapper: {error}"))?;
    if output.status.success() {
        Ok(())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).trim().to_owned())
    }
}

fn main() -> cosmic::iced::Result {
    cosmic::applet::run::<Applet>(())
}
