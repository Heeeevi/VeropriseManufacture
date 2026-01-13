import { useState, useEffect } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import { useAuth } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useToast } from '@/hooks/use-toast';
import { Plus, Search, Edit, Trash2, UserPlus, Shield, Key, Mail, AlertTriangle } from 'lucide-react';
import type { AppRole } from '@/types/database';

interface UserWithRole {
  id: string;
  user_id: string;
  full_name: string;
  email: string;
  phone: string | null;
  role: AppRole | null;
  created_at: string;
}

export default function Users() {
  const { isOwner, user: currentUser } = useAuth();
  const { toast } = useToast();
  const [users, setUsers] = useState<UserWithRole[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [showRoleDialog, setShowRoleDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserWithRole | null>(null);
  const [selectedRole, setSelectedRole] = useState<AppRole>('staff');
  
  // Edit form
  const [editForm, setEditForm] = useState({
    full_name: '',
    phone: '',
    new_password: '',
  });

  // Add user form
  const [addForm, setAddForm] = useState({
    email: '',
    password: '',
    full_name: '',
    phone: '',
    role: 'staff' as AppRole,
  });

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      // Get profiles with their roles
      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (profiles) {
        // Get roles for each user
        const usersWithRoles: UserWithRole[] = await Promise.all(
          profiles.map(async (profile: any) => {
            const { data: roleData } = await supabase
              .from('user_roles')
              .select('role')
              .eq('user_id', profile.user_id)
              .single();

            return {
              id: profile.id,
              user_id: profile.user_id,
              full_name: profile.full_name,
              email: profile.user_id, // We don't have email in profiles, using user_id as placeholder
              phone: profile.phone,
              role: roleData?.role as AppRole | null,
              created_at: profile.created_at,
            };
          })
        );

        setUsers(usersWithRoles);
      }
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAssignRole = async () => {
    if (!selectedUser) return;

    try {
      // Check if user already has a role
      const { data: existing } = await supabase
        .from('user_roles')
        .select('id')
        .eq('user_id', selectedUser.user_id)
        .single();

      if (existing) {
        // Update existing role
        const { error } = await supabase
          .from('user_roles')
          .update({ role: selectedRole })
          .eq('user_id', selectedUser.user_id);

        if (error) throw error;
      } else {
        // Insert new role
        const { error } = await supabase
          .from('user_roles')
          .insert({ user_id: selectedUser.user_id, role: selectedRole });

        if (error) throw error;
      }

      toast({ title: 'Berhasil', description: 'Role berhasil diupdate' });
      setShowRoleDialog(false);
      fetchUsers();
    } catch (error: any) {
      console.error('Error assigning role:', error);
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    }
  };

  const handleRemoveRole = async (userId: string) => {
    try {
      const { error } = await supabase
        .from('user_roles')
        .delete()
        .eq('user_id', userId);

      if (error) throw error;

      toast({ title: 'Berhasil', description: 'Role berhasil dihapus' });
      fetchUsers();
    } catch (error: any) {
      console.error('Error removing role:', error);
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    }
  };

  // Update user profile (name, phone, password)
  const handleUpdateUser = async () => {
    if (!selectedUser) return;

    try {
      // Update profile
      const { error: profileError } = await supabase
        .from('profiles')
        .update({
          full_name: editForm.full_name,
          phone: editForm.phone || null,
        })
        .eq('user_id', selectedUser.user_id);

      if (profileError) throw profileError;

      // Update password if provided (using admin API workaround)
      if (editForm.new_password && editForm.new_password.length >= 6) {
        // Note: This requires service_role key or Edge Function
        // For now, we'll just show a message
        toast({ 
          title: 'Info', 
          description: 'Password update requires Supabase Edge Function. Profile updated successfully.',
        });
      }

      toast({ title: 'Berhasil', description: 'Data pengguna berhasil diupdate' });
      setShowEditDialog(false);
      fetchUsers();
    } catch (error: any) {
      console.error('Error updating user:', error);
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    }
  };

  // Delete user (profile only - auth user stays but can't access)
  const handleDeleteUser = async () => {
    if (!selectedUser || selectedUser.user_id === currentUser?.id) {
      toast({ title: 'Error', description: 'Tidak bisa menghapus diri sendiri', variant: 'destructive' });
      return;
    }

    try {
      // Delete role first
      await supabase.from('user_roles').delete().eq('user_id', selectedUser.user_id);
      
      // Delete profile
      const { error } = await supabase
        .from('profiles')
        .delete()
        .eq('user_id', selectedUser.user_id);

      if (error) throw error;

      toast({ title: 'Berhasil', description: 'Pengguna berhasil dihapus dari sistem' });
      setShowDeleteDialog(false);
      fetchUsers();
    } catch (error: any) {
      console.error('Error deleting user:', error);
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    }
  };

  // Add new user (register without email verification)
  const handleAddUser = async () => {
    if (!addForm.email || !addForm.password || !addForm.full_name) {
      toast({ title: 'Error', description: 'Email, password, dan nama harus diisi', variant: 'destructive' });
      return;
    }

    try {
      // Create user via Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: addForm.email,
        password: addForm.password,
        options: {
          data: { full_name: addForm.full_name },
        },
      });

      if (authError) throw authError;

      if (authData.user) {
        // Wait a bit for trigger to create profile
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Assign role
        const { error: roleError } = await supabase
          .from('user_roles')
          .insert({ user_id: authData.user.id, role: addForm.role });

        if (roleError) {
          console.error('Role assignment error:', roleError);
        }

        // Update profile with phone if provided
        if (addForm.phone) {
          await supabase
            .from('profiles')
            .update({ phone: addForm.phone })
            .eq('user_id', authData.user.id);
        }
      }

      toast({ 
        title: 'Berhasil', 
        description: 'User baru berhasil dibuat. User bisa langsung login tanpa verifikasi email (jika Supabase confirm email disabled).' 
      });
      setShowAddDialog(false);
      setAddForm({ email: '', password: '', full_name: '', phone: '', role: 'staff' });
      fetchUsers();
    } catch (error: any) {
      console.error('Error adding user:', error);
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    }
  };

  const getRoleBadge = (role: AppRole | null) => {
    switch (role) {
      case 'owner':
        return <Badge className="bg-primary">Owner</Badge>;
      case 'manager':
        return <Badge className="bg-info">Manager</Badge>;
      case 'staff':
        return <Badge className="bg-accent text-accent-foreground">Staff</Badge>;
      case 'investor':
        return <Badge variant="outline">Investor</Badge>;
      default:
        return <Badge variant="secondary">No Role</Badge>;
    }
  };

  const filteredUsers = users.filter(
    (u) =>
      u.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      u.user_id.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <MainLayout>
      <div className="p-6 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="font-display text-2xl font-semibold">Manajemen Pengguna</h1>
            <p className="text-muted-foreground">Kelola user dan role akses</p>
          </div>
          {isOwner && (
            <Button onClick={() => setShowAddDialog(true)}>
              <UserPlus className="h-4 w-4 mr-2" />
              Tambah User
            </Button>
          )}
        </div>

        {isOwner && (
          <Alert className="border-yellow-500/50 bg-yellow-500/10">
            <AlertTriangle className="h-4 w-4 text-yellow-500" />
            <AlertDescription>
              <strong>Tips:</strong> Untuk agar user baru bisa langsung login tanpa verifikasi email, 
              matikan "Enable email confirmations" di Supabase Dashboard → Authentication → Providers → Email.
            </AlertDescription>
          </Alert>
        )}

        <Card className="card-warm">
          <CardHeader>
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <CardTitle className="font-display">Daftar Pengguna</CardTitle>
              <div className="relative w-full md:w-64">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Cari pengguna..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Nama</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Telepon</TableHead>
                  <TableHead>Terdaftar</TableHead>
                  <TableHead className="text-right">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium">{user.full_name}</div>
                        <div className="text-xs text-muted-foreground">{user.user_id.substring(0, 8)}...</div>
                      </div>
                    </TableCell>
                    <TableCell>{getRoleBadge(user.role)}</TableCell>
                    <TableCell>{user.phone || '-'}</TableCell>
                    <TableCell>{new Date(user.created_at).toLocaleDateString('id-ID')}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          title="Assign Role"
                          onClick={() => {
                            setSelectedUser(user);
                            setSelectedRole(user.role || 'staff');
                            setShowRoleDialog(true);
                          }}
                        >
                          <Shield className="h-4 w-4" />
                        </Button>
                        {isOwner && (
                          <>
                            <Button
                              variant="ghost"
                              size="icon"
                              title="Edit User"
                              onClick={() => {
                                setSelectedUser(user);
                                setEditForm({
                                  full_name: user.full_name,
                                  phone: user.phone || '',
                                  new_password: '',
                                });
                                setShowEditDialog(true);
                              }}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            {user.user_id !== currentUser?.id && (
                              <Button
                                variant="ghost"
                                size="icon"
                                className="text-destructive hover:text-destructive"
                                title="Hapus User"
                                onClick={() => {
                                  setSelectedUser(user);
                                  setShowDeleteDialog(true);
                                }}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            )}
                          </>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                {filteredUsers.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                      {loading ? 'Memuat...' : 'Tidak ada pengguna'}
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      {/* Role Assignment Dialog */}
      <Dialog open={showRoleDialog} onOpenChange={setShowRoleDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-display">Assign Role</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <p className="text-sm text-muted-foreground">
              Assign role untuk: <strong>{selectedUser?.full_name}</strong>
            </p>
            <div className="space-y-2">
              <Label>Role</Label>
              <Select value={selectedRole} onValueChange={(v) => setSelectedRole(v as AppRole)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="owner">Owner - Akses penuh</SelectItem>
                  <SelectItem value="manager">Manager - Kelola outlet</SelectItem>
                  <SelectItem value="staff">Staff - POS & input data</SelectItem>
                  <SelectItem value="investor">Investor - Lihat laporan saja</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRoleDialog(false)}>Batal</Button>
            <Button onClick={handleAssignRole}>Simpan</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit User Dialog */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-display flex items-center gap-2">
              <Edit className="h-5 w-5" />
              Edit Pengguna
            </DialogTitle>
            <DialogDescription>
              Edit data untuk: {selectedUser?.full_name}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Nama Lengkap</Label>
              <Input 
                value={editForm.full_name} 
                onChange={(e) => setEditForm({ ...editForm, full_name: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label>No. Telepon</Label>
              <Input 
                value={editForm.phone} 
                onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                placeholder="08123456789"
              />
            </div>
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Key className="h-4 w-4" />
                Password Baru (opsional)
              </Label>
              <Input 
                type="password"
                value={editForm.new_password} 
                onChange={(e) => setEditForm({ ...editForm, new_password: e.target.value })}
                placeholder="Kosongkan jika tidak ingin ubah"
              />
              <p className="text-xs text-muted-foreground">
                Minimal 6 karakter. Perubahan password memerlukan Supabase Edge Function.
              </p>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowEditDialog(false)}>Batal</Button>
            <Button onClick={handleUpdateUser}>Simpan Perubahan</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete User Dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="font-display text-destructive flex items-center gap-2">
              <AlertTriangle className="h-5 w-5" />
              Hapus Pengguna
            </DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus pengguna ini?
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <div className="bg-destructive/10 border border-destructive/20 rounded-lg p-4">
              <p className="font-medium">{selectedUser?.full_name}</p>
              <p className="text-sm text-muted-foreground">{selectedUser?.role || 'No Role'}</p>
            </div>
            <p className="text-sm text-muted-foreground mt-4">
              Pengguna akan dihapus dari sistem dan tidak bisa mengakses aplikasi lagi.
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>Batal</Button>
            <Button variant="destructive" onClick={handleDeleteUser}>Ya, Hapus</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Add User Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="font-display flex items-center gap-2">
              <UserPlus className="h-5 w-5" />
              Tambah Pengguna Baru
            </DialogTitle>
            <DialogDescription>
              Buat akun baru untuk staff atau manager
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label>Email *</Label>
              <Input 
                type="email"
                value={addForm.email} 
                onChange={(e) => setAddForm({ ...addForm, email: e.target.value })}
                placeholder="user@example.com"
              />
            </div>
            <div className="space-y-2">
              <Label>Password *</Label>
              <Input 
                type="password"
                value={addForm.password} 
                onChange={(e) => setAddForm({ ...addForm, password: e.target.value })}
                placeholder="Minimal 6 karakter"
              />
            </div>
            <div className="space-y-2">
              <Label>Nama Lengkap *</Label>
              <Input 
                value={addForm.full_name} 
                onChange={(e) => setAddForm({ ...addForm, full_name: e.target.value })}
                placeholder="John Doe"
              />
            </div>
            <div className="space-y-2">
              <Label>No. Telepon</Label>
              <Input 
                value={addForm.phone} 
                onChange={(e) => setAddForm({ ...addForm, phone: e.target.value })}
                placeholder="08123456789"
              />
            </div>
            <div className="space-y-2">
              <Label>Role</Label>
              <Select value={addForm.role} onValueChange={(v) => setAddForm({ ...addForm, role: v as AppRole })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="staff">Staff - POS & input data</SelectItem>
                  <SelectItem value="manager">Manager - Kelola outlet</SelectItem>
                  <SelectItem value="owner">Owner - Akses penuh</SelectItem>
                  <SelectItem value="investor">Investor - Lihat laporan</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>Batal</Button>
            <Button onClick={handleAddUser}>Buat Akun</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </MainLayout>
  );
}
