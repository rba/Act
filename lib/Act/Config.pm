use strict;
package Act::Config;

use vars qw(@ISA @EXPORT $Config %Request %Languages);
@ISA    = qw(Exporter);
@EXPORT = qw($Config %Request %Languages );

use AppConfig qw(:expand :argcount);

# our configs
my ($GlobalConfig, %ConfConfigs);

# language-specific constants
%Languages = (
    fr => { name               => 'fran�ais',
            fmt_datetime_full  => '%A %e %B %Y %Hh%M',
            fmt_datetime_short => '%d/%m/%y %Hh%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%Hh%M',
          },
    de => { name               => 'Deutsch',
            fmt_datetime_full  => '%A, %e. %B %Y %H.%M',
            fmt_datetime_short => '%d.%m.%Y %H.%M',
            fmt_date_full      => '%A, %e. %B %Y',
            fmt_date_short     => '%d.%m.%Y',
            fmt_time           => '%H.%M',
          },
    en => { name               => 'English',
            fmt_datetime_full  => '%A %B %e, %Y %H:%M',
            fmt_datetime_short => '%m/%d/%y %H:%M',
            fmt_date_full      => '%A %B %e, %Y',
            fmt_date_short     => '%m/%d/%y',
            fmt_time           => '%H:%M',
          },
    es => { name               => 'Espa�ol',
            fmt_datetime_full  => '%e %B %Y %Hh%M',
            fmt_datetime_short => '%d/%m/%Y %Hh%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%Y',
            fmt_time           => '%Hh%M',
          },
    pt => { name               => 'Portugu�s',
            fmt_datetime_full  => '%A, %e de %B de %Y, %H:%M',
            fmt_datetime_short => '%y/%m/%d %H:%M',
            fmt_date_full      => '%A, %e de %B de %Y',
            fmt_date_short     => '%y/%m/%d',
            fmt_time           => '%H:%M',
          },
    it => { name               => 'Italiano',
            fmt_datetime_full  => '%A %e %B %Y, %H:%M',
            fmt_datetime_short => '%d/%m/%y %H:%M',
            fmt_date_full      => '%A %e %B %Y',
            fmt_date_short     => '%d/%m/%y',
            fmt_time           => '%H:%M',
          },
);

# load configurations
load_configs();

sub load_configs
{
    my $home = $ENV{ACTHOME} or die "ACTHOME environment variable isn't set\n";
    $GlobalConfig = _init_config($home);

    # load global configuration
    _load_config($GlobalConfig, $home);
    _make_hash  ($GlobalConfig, conferences => $GlobalConfig->general_conferences);

    # load conference-specific configuration files
    # their content may override global config settings
    my %uris;
    for my $conf (keys %{$GlobalConfig->conferences}) {
        $ConfConfigs{$conf} = _init_config($home);
        _load_config($ConfConfigs{$conf}, $home);
        _load_config($ConfConfigs{$conf}, "$home/actdocs/$conf");
        _make_hash($ConfConfigs{$conf}, languages => $ConfConfigs{$conf}->general_languages);
        _make_hash($ConfConfigs{$conf}, talks_durations => $ConfConfigs{$conf}->talks_durations);
        _make_hash($ConfConfigs{$conf}, rooms => $ConfConfigs{$conf}->rooms_rooms);
        $ConfConfigs{$conf}->rooms->{$_} = $ConfConfigs{$conf}->get("rooms_$_")
            for keys %{$ConfConfigs{$conf}->rooms};
        $ConfConfigs{$conf}->set(name => { });
        $ConfConfigs{$conf}->name->{$_} = $ConfConfigs{$conf}->get("general_name_$_")
            for keys %{$ConfConfigs{$conf}->languages};
        $ConfConfigs{$conf}->languages->{$_} = $Languages{$_}
            for keys %{$ConfConfigs{$conf}->languages};
        # conf <=> uri mapping
        my $uri = $ConfConfigs{$conf}->general_uri || $conf;
        $uris{$uri} = $conf;
        $ConfConfigs{$conf}->set(uri => $uri);
        # general_conferences isn't overridable
        $ConfConfigs{$conf}->set(conferences => $GlobalConfig->conferences);
    }
    # install uri to conf mapping
    $GlobalConfig->set(uris => \%uris);
    $ConfConfigs{$_}->set(uris => \%uris) for keys %{$GlobalConfig->conferences};

    # default current config (for non-web stuff that doesn't call get_config)
    $Config = $GlobalConfig;
}
# get configuration for current request
sub get_config
{
    my $conf = shift;
    return $conf && $ConfConfigs{$conf}
         ? $ConfConfigs{$conf}
         : $GlobalConfig;
}

sub _init_config
{
    my $home = shift;
    my $cfg = AppConfig->new(
         {
            CREATE => 1,
            GLOBAL => {
                   DEFAULT  => "<undef>",
                   ARGCOUNT => ARGCOUNT_ONE,
                   EXPAND   => EXPAND_VAR,
               }
         }
    );
    $cfg->set(home => $home);
    return $cfg;
}

sub _load_config
{
    my ($cfg, $dir) = @_;
    for my $file qw(act local) {
        my $path = "$dir/conf/$file.ini";
        $cfg->file($path) if -e $path;
    }
}

sub _make_hash
{
    my ($cfg, %h) = @_;
    while (my ($key, $value) = each %h) {
        $cfg->set($key => { map { $_ => 1 } split /\s+/, $value });
    }
}
1;
__END__

=head1 NAME

Act::Config - read configuration files

=head1 SYNOPSIS

    use Act::Config;
    Act::Config::get_config($conference);

=cut
